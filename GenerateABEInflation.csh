#!/bin/csh

date

#
# Setup environment:
# =============================================
source ./control.csh
set yymmdd = `echo ${CYLC_TASK_CYCLE_POINT} | cut -c 1-8`
set hh = `echo ${CYLC_TASK_CYCLE_POINT} | cut -c 10-11`
set thisCycleDate = ${yymmdd}${hh}
set thisValidDate = ${thisCycleDate}
source ./getCycleVars.csh

set self_StatePrefix = ${FCFilePrefix}

set self_WorkDir = $CyclingABEInflationDir
echo "WorkDir = ${self_WorkDir}"
mkdir -p ${self_WorkDir}
cd ${self_WorkDir}

set self_AppType = ${omm}

## link static fields:
ln -sf ${staticFieldsFile} ${localStaticFieldsFile}

# gridTemplateFile must include latCell, lonCell, theta, and surface_pressure
set gridTemplateFile = ${self_WorkDir}/${localStaticFieldsFile}

# could use mean state, but not guaranteed to have all required fields
#set meanStatePrefix = ${FCFilePrefix}
#set meanName = ${meanStatePrefix}.$fileDate.nc
#set gridTemplateFile = $MeanBackgroundDir/$meanName


# location of mean background obs-space hofx database
set dbPath = ${VerifyEnsMeanBGDirs}/${OutDBDir}

set self_ObsList = (abi_g16)
set nInstAvailable = 0
#set instrumentArg = ''
foreach inst ($self_ObsList)
  set missing = 0
  # TODO: define obsoutGlob construction in a different place
  set obsoutGlob = "${dbPath}/obsout_${self_AppType}_${inst}_*.nc4"
  echo "Searching for ${obsoutGlob}"
  find ${obsoutGlob} -mindepth 0 -maxdepth 0
  if ($? > 0) then
    @ missing++
  else
    set brokenLinks=( `find ${obsoutGlob} -mindepth 0 -maxdepth 0 -type l -exec test ! -e {} \; -print` )
    foreach link ($brokenLinks)
      @ missing++
    end
  endif
  if ($missing == 0) then
#    set instrumentArg = $instrumentArg${inst},
    echo "${inst} data was found successfully"
    @ nInstAvailable++
  else
    echo "${inst} data is selected, but missing; NOT adding ${inst} to ABE instruments"
  endif
end

if ($nInstAvailable == 0) then
  exit 0
endif

module load python/3.7.5

#
# generate ABE Inflation Factors:
# ======================================================
set mainScript="GenerateABEIFactors"
ln -fs ${pyObsDir}/*.py ./
ln -fs ${pyObsDir}/${mainScript}.py ./

set success = 1
while ( $success != 0 )
  mv log.${mainScript} log.${mainScript}_LAST
  setenv baseCommand "python ${mainScript}.py ${thisValidDate} -p ${dbPath} -o ${obsPrefix} -g ${geoPrefix} -d ${diagPrefix} -m ${gridTemplateFile} -app hofx"

  echo "${baseCommand}"
  ${baseCommand} >& log.${mainScript}

  set success = $?

  if ( $success != 0 ) then
    source /glade/u/apps/ch/opt/usr/bin/npl/ncar_pylib.csh
    sleep 3
  endif
end
cd -

date

exit
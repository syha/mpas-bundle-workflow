#!/bin/csh -f

source config/filestructure.csh

## workflow tools
set pyDir = ${mainScriptDir}/tools
set pyTools = ( \
  memberDir \
  advanceCYMDH \
  nSpaces \
  updateXTIME \
  substituteEnsembleB \
)
foreach tool ($pyTools)
  setenv ${tool} "python ${pyDir}/${tool}.py"
end

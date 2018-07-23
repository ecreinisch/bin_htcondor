#!/bin/bash
#! checks to see if a python dependency is installed or not
# 20180720 Elena C Reinisch

if [[ $# -eq 0 ]]; then
echo "script that checks if a python dependency is installed and displays message"
echo "check_python_modules.sh [module_name] [v, optional for verbose]"
echo "e.g., check_python_modules.sh utm"
echo "e.g., check_python_modules.sh utm v"
exit 1
fi

modl=$1
verb=$2

python -c "import ${modl}"
estat=$(echo $?)

if [[ $verb == "v" ]]; then
echo "Is module installed? (y=0, n=1):"
fi
 
echo $estat

if [[ $verb == "v" ]]; then
if [[ $estat -eq 0 ]]; then
   echo "module installed in default version of python"
elif [[ $estat -eq 1 ]]; then
   echo "Module is not installed in default version!  Consider installing or running miniconda"
else
   echo "Script did not finish correctly. Try manually checking for module"
fi
fi

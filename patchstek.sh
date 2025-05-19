#!/bin/bash

if [ "${PWD##*/}" != "AIS-catcher" ] ; then
  echo "ERROR! Please run from \"AIS-catcher\" folder. Exiting..."
  exit 9
fi

echo ""

function pa(){
  infile="$(echo "${1}"|sed 's/[\.\/]/_/g').patch"
  if [ ! -e "${1}.orig" ] ; then
    echo "creating backup file \"${1}.orig\""
    cp ${1} ${1}.orig
  fi
  patch ${1} < ../stek-aispatcher/${infile}
  if [ $? -gt 0 ]; then
    echo "ERROR DETECTED!"
    CNT=$((CNT+1))
  fi
  echo ""
}

CNT=0

while IFS= read -r file
do
   [ "$file" != "" ] && pa "$file"
done < "../stek-aispatcher/filelist.list"

if [ $CNT -gt 0 ]; then
  echo ""
  echo "Found $CNT questionable patching attempts.."
  read -p "do you want to continnue (y/[n])?" answer
  if [ ! "$answer" == "y" ]; then
    echo "EXITING"
    exit 10
  fi
fi
echo "Done"

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
   echo ""
}

while IFS= read -r file
do
   [ "$file" != "" ] && pa "$file"
done < "../stek-aispatcher/filelist.list"

echo "Done"

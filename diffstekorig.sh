#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

if [ "${PWD##*/}" != "stek-aispatcher" ] ; then
   echo "ERROR! Please run from \"stek-aispatcher\" folder. Exiting..."
   exit 9
fi


if [ ! -d "../AIS-catcher" ] ; then
   echo "ERROR! Cant find \"../AIS-catcher/\""
   exit 8
fi

datetime="$(date +"%Y%m%d-%H%M%S")"

echo "Backing up to \"filelist.list.${datetime}\""
mv filelist.list filelist.list.${datetime}
for filename in *.patch ; do
   [ -e "${filename}" ] || continue
   echo "Backing up to \"${filename}.${datetime}\""
   mv ${filename} ${filename}.${datetime}
done

cd ../AIS-catcher

find|grep "\.orig$"|sed 's/\.\///g' > filelist.listorig

echo ""
gitlist=""
while IFS= read -r file
do
   [ -f "${file}" ] || continue;
   infile="${file%%.orig}"
   ofile="$(echo "${infile}"|sed 's/[\.\/]/_/g').patch"
   outfile="../stek-aispatcher/${ofile}"
   echo "compairing ${file} to ${infile}, results in ${outfile}"
   diff -u ${file} ${infile} > ${outfile}
   echo "${infile}" >> ../stek-aispatcher/filelist.list
   echo ""
   gitlist="${gitlist} ${ofile}"
done < "filelist.listorig"

rm "filelist.listorig"
cd ../stek-aispatcher

git add${gitlist}

echo "Done"

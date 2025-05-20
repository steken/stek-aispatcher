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

echo "Backing up to \"patches.${datetime}\""
mv patches patches.${datetime}
mkdir patches

cd ../AIS-catcher

find|grep "\.orig$"|sed 's/\.\///g' > filelist.listorig

echo ""

echo "generating \"AIS-catcher.githash\""
git show -s --format="%H" HEAD > ../stek-aispatcher/patches/AIS-catcher.githash

gitlist=" patches/AIS-catcher.githash"
while IFS= read -r file
do
   [ -f "${file}" ] || continue;
   infile="${file%%.orig}"
   ofile="$(echo "${infile}"|sed 's/[\.\/]/_/g').patch"
   outfile="../stek-aispatcher/patches/${ofile}"
   echo "compairing ${file} to ${infile}, results in ${outfile}"
   diff -u ${file} ${infile} > ${outfile}
   echo "${infile}" >> ../stek-aispatcher/patches/filelist.list
   echo ""
   gitlist="${gitlist} patches/${ofile}"
done < "filelist.listorig"

rm "filelist.listorig"

echo ""

cd ../stek-aispatcher

git add patches ${gitlist}

echo "Done"
echo ""
[ -e "git_token" ] && cat git_token
echo ""
echo "Please run:"
echo ""
echo "git commit"
echo "git push"
echo ""

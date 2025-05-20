#!/bin/bash

if [ "${PWD##*/}" != "AIS-catcher" ] ; then
  echo "ERROR! Please run from \"AIS-catcher\" folder. Exiting..."
  exit 9
fi

if [ ! -f "../stek-aispatcher/patches/AIS-catcher.githash" ] ; then
  echo "ERROR! The file \"../stek-aispatcher/patches/AIS-catcher.githash\" does not exist. Exiting..."
  exit 8
fi

echo ""
CHASH="$(git log -n 1 --oneline | cut -d' ' -f 1)"
PHASH="$(cat ../stek-aispatcher/patches/AIS-catcher.githash | head -c 8)"
NUMBER="$(($(git log --oneline | grep -n "^$PHASH "|cut -d':' -f 1) -1))"

CHOICE=$(whiptail --title "What to patch?" --menu "Select a option" 20 80 10 \
   "1" "Patch CURRENT sources,  hash '$CHASH', currently $NUMBER commits ahead" \
   "2" "Patch MATCHING sources, hash '$PHASH'" \
   "3" "Patch OTHER number ahead of patches " \
   "4" "NO patching" \
   "5" "EXIT" 3>&1 1>&2 2>&3);

if [ "$CHOICE" == "1" ]; then
  echo "Patch CURRENT sources"
elif [ "$CHOICE" == "2" ]; then
  echo "Patch MATCHING sources"
  git reset --hard "$PHASH"
elif [ "$CHOICE" == "3" ]; then
  echo "Patch OTHER number ahead"
  echo ""
  git log -n $NUMBER --oneline|tac|cat -n|tac
  echo "Please enter a number:"
  read LINE
  GITLINE="$(git log -n $NUMBER --oneline|tail -n $LINE|head -n 1)"
  echo "selected line '$LINE' - '$GITLINE'"
  PHASH="$(echo "$GITLINE"|cut -d ' ' -f 1)"
  git reset --hard "$PHASH"
elif [ "$CHOICE" == "4" ]; then
  echo "NO patching"
  exit 0
else
  echo "EXIT"
  exit 10
fi

function pa(){
  infile="$(echo "${1}"|sed 's/[\.\/]/_/g').patch"
  if [ ! -e "${1}.orig" ] ; then
    echo "creating backup file \"${1}.orig\""
    cp ${1} ${1}.orig
  fi
  patch ${1} < ../stek-aispatcher/patches/${infile}
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
done < "../stek-aispatcher/patches/filelist.list"

if [ $CNT -gt 0 ]; then
  echo ""
  echo "Found $CNT questionable patching attempts.."
  read -p "do you want to continnue (y/[n])?" answer
  if [ ! "$answer" == "y" ]; then
    echo "EXITING"
    exit 11
  fi
fi
echo "Done"

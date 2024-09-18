#!/bin/bash
set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

INSTALL_FOLDER=/usr/share/aiscatcher
currentver="$(grep "VERSION_DESCRIBE" ${INSTALL_FOLDER}/AIS-catcher/Application/AIS-catcher.h | cut -d '"' -f 2)"
datetime="$(echo "${currentver}" | cut -d '_' -f 3)"
if [ -z ${datetime} ] ; then
   datetime="$(date +"%Y%m%d-%H%M%S")"
fi

if [ "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" == "${INSTALL_FOLDER}/stek-aispatcher" ] ; then
  if [ ! "$EUID" -ne 0 ]; then
    echo "Please, do not run as root from ${INSTALL_FOLDER}/stek-aispatcher."
    exit 7
  fi
  echo "Copying \"install-aispatcher.sh\" to \"$HOME\""
  cp ${INSTALL_FOLDER}/stek-aispatcher/install-aispatcher.sh $HOME
  echo "DONE!"
  echo ""
  exit 8
fi

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 9
fi

echo "Current version is ${currentver}"

echo "Checking for old backups ..."
cd ${INSTALL_FOLDER}


buplist="$(ls -o | grep "\.bup$")"

choises="$(while IFS= read -r bup; do
  if [ -e "AIS-catcher.$bup.bup/Application/AIS-catcher.h" ]; then
    ver="$(grep "VERSION_DESCRIBE" AIS-catcher.$bup.bup/Application/AIS-catcher.h | cut -d '"' -f 2)---------------------------------------------------"
  else
    ver="-------------------------------------------"
  fi
  echo "$bup ${ver:0:42}-$(echo "$buplist" | grep "$bup\.bup$" | rev | cut -d' ' -f1 | cut -d'.' -f 3- | rev | head -c -1 | tr '\n' '+')"
done <<< "$(echo "$buplist" | rev | cut -d'.' -f2 | rev | sort -r | uniq)")"

CHOICE=$(whiptail --title "Build or Restore?" --menu "Current version is ${currentver}. Select a option" 0 0 0 -- "Build" "Build new version..." $choises 3>&1 1>&2 2>&3);

echo "$CHOICE"

if [ "$CHOICE" != "Build" ]; then
  movebin="no"
  choises="$(while IFS= read -r bup; do
  echo "$bup resore on"
done <<< "$(echo "$buplist" | grep "$CHOICE" | rev | cut -d' ' -f1 | rev)")"

  nextCHOICE="$(whiptail --title "Restore?" --checklist "Select items to restore" 0 0 0 -- $choises 3>&1 1>&2 2>&3 | tr '"' ' ')";

  echo "$nextCHOICE"

  for restore in $nextCHOICE; do
    basename="$(echo "$restore" | rev | cut -d'.' -f3- | rev)"
    if [ "$basename" == "aiscatcher.service" ]; then
      filename="/lib/systemd/system/$basename"
    else
      filename="$basename"
    fi
    if [ -e "$basename.$datetime.bup" ]; then
      CHOICE=$(whiptail --title "CONFIG" --menu "An existing copy \"$basename.$datetime.bup\" found. What you want to do with it?" 0 0 0 \
"1" "KEEP existing \"$basename.$datetime.bup\", discard \"$filename\"." \
"2" "REPLACE \"$basename.$datetime.bup\"." \
"3" "CREATE backup as \"$basename.$currentver.bup\"." 3>&1 1>&2 2>&3);

      if [ ${CHOICE} == "1" ] ; then
        echo "removing \"$filename\""
        rm -rf "$filename"
      elif [ ${CHOICE} == "2" ] ; then
        echo "removing \"$basename.$datetime.bup\""
        rm -rf "$basename.$datetime.bup"
      elif [ ${CHOICE} == "3" ] ; then
        echo "moving \"$filename\" to \"$basename.$currentver.bup\"..."
        mv "$filename" "$basename.$currentver.bup"
      fi
    fi
    if [ ! -e "$basename.$datetime.bup" -a -e "$filename" ]; then
      echo "moving \"$filename\" to \"$basename.$datetime.bup\"..."
      mv "$filename" "$basename.$datetime.bup"
    fi
    echo "moving \"$restore\" to \"$filename\"..."
    mv "$restore" "$filename"
    if [ "$basename" == "AIS-catcher" ]; then
      movebin="yes"
    fi
  done
  echo ""

  servicewas=""
  if [ "$(systemctl is-active aiscatcher.service)" != "inactive" ]; then
    servicewas="running"
    echo "Stopping \"aiscatcher.service\""
    systemctl stop aiscatcher.service
  fi
  if [ "$movebin" == "yes" ]; then
    if [ -f "${INSTALL_FOLDER}/AIS-catcher/build/AIS-catcher" ]; then
      if [ $(pgrep AIS-catcher) ]; then
        killall AIS-catcher
      fi
      echo "Copying binary \"AIS-catcher\" to folder \"/usr/local/bin/\""
      cp ${INSTALL_FOLDER}/AIS-catcher/build/AIS-catcher /usr/local/bin/AIS-catcher
    else
      echo "ERROR - AIS binary do not exist, removing from  \"/usr/local/bin/\""
      rm -f "/usr/local/bin/AIS-catcher"
    fi
  fi
  if [ "$(systemctl is-enabled aiscatcher.service)" != "disabled" -o "$servicewas" == "running" ]; then
    systemctl start aiscatcher.service
  fi

  echo "DONE"
  echo ""
  exit 0
fi

cd

echo "Checking dependensies ..."
apt update
list="$(apt list --installed)"
listinst=""
for package in git make gcc g++ cmake pkg-config librtlsdr-dev whiptail minify xxd bc; do
  if [ "$(echo "${list}" | grep "^${package}/" | grep "installed")" == "" ] ; then
    echo "${package} NOT installed"
    listinst="${listinst} ${package}"
  else
    echo "${package} already installed"
  fi
done
echo ""
if [ "${listinst}" != "" ] ; then
    echo "Installing${listinst}"
    apt install -y${listinst}
    echo ""
fi

if [ -d ${INSTALL_FOLDER}/stek-aispatcher ] ; then
  echo "Backing up old source"
  mv ${INSTALL_FOLDER}/stek-aispatcher ${INSTALL_FOLDER}/stek-aispatcher.${datetime}.bup
fi

if [ ! -d ${INSTALL_FOLDER} ] ; then 
  echo "Creating folder \"${INSTALL_FOLDER}\""
  mkdir -p ${INSTALL_FOLDER}
fi

echo "Entering install folder..."
cd ${INSTALL_FOLDER}

echo "Removeing old source..."
rm -rf stek-aispatcher
echo "Cloning source-code of stek-aispatcher from Github..."
git clone https://github.com/steken/stek-aispatcher.git
cd ${INSTALL_FOLDER}/stek-aispatcher
git config --global --add safe.directory ${INSTALL_FOLDER}/stek-aispatcher
git fetch --all
git reset --hard origin/main

set +e

./install-stek-aiscatcher.sh 3

if [ "$SUDO_USER" != "" ] ; then
  su -c 'sleep 1 ; ./install-aispatcher.sh ' $SUDO_USER &
fi

#!/bin/bash
set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

datetime="$(date +"%Y%m%d-%H%M%S")"
INSTALL_FOLDER=/usr/share/aiscatcher

if [ "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" == "${INSTALL_FOLDER}/stek-aispatcher" ] ; then
  echo "Please, do not run from ${INSTALL_FOLDER}/stek-aispatcher."
  if [ ! "$EUID" -ne 0 ]; then
    echo "Please do not run as root at this moment."
    exit 7
  fi
  echo "Copying to $HOME"
  cp ${INSTALL_FOLDER}/stek-aispatcher/install-aispatcher.sh $HOME
  exit 8
fi

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 9
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
cd ${INSTALL_FOLDER}
git config --global --add safe.directory ${INSTALL_FOLDER}
git fetch --all
git reset --hard origin/main

./install-stek-aiscatcher.sh 3

#!/bin/bash
set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

#datetime="$(date +"%Y%m%d-%H%M%S")"
INSTALL_FOLDER=/usr/share/aiscatcher/stek-aispatcher

if [ "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" == "${INSTALL_FOLDER}" ] ; then
  echo "Please, do not run from ${INSTALL_FOLDER}."
  if [ ! "$EUID" -ne 0 ]; then
    echo "Please do not run as root at this moment."
    exit 7
  fi
  echo "Copying to $HOME"
  cp ${INSTALL_FOLDER}/install-aispatcher.sh $HOME
  exit 8
fi

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 9
fi

if [ ! -e ${INSTALL_FOLDER} ] ; then
   echo "Creating folder \"${INSTALL_FOLDER}\""
   mkdir -p ${INSTALL_FOLDER}
fi

#echo "Installing build tools and dependencies..."
#apt-get update
#apt-get install -y git make gcc g++ cmake pkg-config librtlsdr-dev whiptail minify xxd

echo "Entering install folder..."
cd ${INSTALL_FOLDER}
cd ..

echo "Removeing old source..."
rm -rf stek-aispatcher
echo "Cloning source-code of stek-aispatcher from Github..."
git clone https://github.com/steken/stek-aispatcher.git
cd ${INSTALL_FOLDER}
git config --global --add safe.directory ${INSTALL_FOLDER}
git fetch --all
git reset --hard origin/main

./install-stek-aiscatcher.sh 3

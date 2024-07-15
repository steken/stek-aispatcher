#!/bin/bash
set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

# Contributions to https://github.com/abcd567a/install-aiscatcher

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

INSTALL_FOLDER=/usr/share/aiscatcher
datetime="$(grep "VERSION_DESCRIBE" ${INSTALL_FOLDER}/AIS-catcher/Application/AIS-catcher.h | cut -d '"' -f 2 | cut -d '_' -f 3)"
if [ -z ${datetime} ] ; then
   datetime="$(date +"%Y%m%d-%H%M%S")"
fi
INSTALL_PLUGINS=""
DOWNLOAD="NO"
INSTALL_STEK_PATCHES="NO"
INSTALL_BUILD_TOOLS="NO"

if [ -d ${INSTALL_FOLDER}/AIS-catcher ] ; then
   echo "Found folder \"${INSTALL_FOLDER}/AIS-catcher\", copying to backup. Asuming build tools are already installed."
   cp -r ${INSTALL_FOLDER}/AIS-catcher ${INSTALL_FOLDER}/AIS-catcher.$datetime.bup
else
   if (whiptail --title "Build tools" --yesno "Do you want to install build-tools?" 10 60 ); then
      INSTALL_BUILD_TOOLS="YES"
   fi

   echo "Creating folder \"${INSTALL_FOLDER}\""
   mkdir -p ${INSTALL_FOLDER}
fi

if [ "$1" == "1"] ; then
   echo "1 - build LOCAL sources"
   CHOICE=1
elif [ "$1" == "2"] ; then
   echo "2 - PATCH and build LOCAL sources"
   CHOICE=2
elif [ "$1" == "3"] ; then
   echo "3 - DOWNLOAD, PATCH and build github sources"
   CHOICE=3
elif [ "$1" == "4"] ; then
   echo "4 - DOWNLOAD and build github sources"
   CHOICE=4
else
   CHOICE=$(whiptail --title "What to build?" --menu "Select a option" 20 60 5 \
   "1" "build LOCAL sources" \
   "2" "PATCH and build LOCAL sources" \
   "3" "DOWNLOAD, PATCH and build github sources" \
   "4" "DOWNLOAD and build github sources" 3>&1 1>&2 2>&3);
fi
if [[ ${CHOICE} == "1" ]]; then
   DOWNLOAD="NO"
elif [[ ${CHOICE} == "2" ]]; then
   INSTALL_STEK_PATCHES="YES"
   DOWNLOAD="NO"
elif [[ ${CHOICE} == "3" ]]; then
   INSTALL_STEK_PATCHES="YES"
   DOWNLOAD="YES"
elif [[ ${CHOICE} == "4" ]]; then
   DOWNLOAD="YES"
fi

function create-config(){
echo "Creating config file aiscatcher.conf"
CONFIG_FILE=${INSTALL_FOLDER}/aiscatcher.conf
touch ${CONFIG_FILE}
chmod 777 ${CONFIG_FILE}
echo "Writing code to config file aiscatcher.conf"
/bin/cat <<EOM >${CONFIG_FILE}
-d:0
-gr TUNER auto RTLAGC on BIASTEE off
-u 127.0.0.1 10110
-N 8383 PLUGIN_DIR /usr/share/aiscatcher/my-plugins STATION "Station" SHARE_LOC on LAT 59.000000 LON 17.000000 REALTIME on MSG on
-q
EOM
chmod 644 ${CONFIG_FILE}
}

if [[ -f ${INSTALL_FOLDER}/aiscatcher.conf ]]; then
   CHOICE=$(whiptail --title "CONFIG" --menu "An existing config file 'aiscatcher.conf' found. What you want to do with it?" 20 60 5 \
   "1" "KEEP existing config file \"aiscatcher.conf\" " \
   "2" "REPLACE existing config file by default config file" 3>&1 1>&2 2>&3);
   if [[ ${CHOICE} == "2" ]]; then
      if (whiptail --title "Confirmation" --yesno "Are you sure you want to REPLACE your existing config file by default config File?" --defaultno 10 60 5 ); then
         echo "Saving old config file as \"aiscatcher.conf.$datetime.bup\" ";
         mv ${INSTALL_FOLDER}/aiscatcher.conf ${INSTALL_FOLDER}/aiscatcher.conf.$datetime.bup;
         create-config
      else
         cp ${INSTALL_FOLDER}/aiscatcher.conf ${INSTALL_FOLDER}/aiscatcher.conf.$datetime.bup;
      fi
   else
      cp ${INSTALL_FOLDER}/aiscatcher.conf ${INSTALL_FOLDER}/aiscatcher.conf.$datetime.bup;
   fi
elif [[ ! -f ${INSTALL_FOLDER}/aiscatcher.conf ]]; then
   create-config
fi

if [[ -d "${INSTALL_FOLDER}/my-plugins" ]]; then
   INSTALL_PLUGINS="OLD"
   CHOICE=$(whiptail --title "CONFIG" --menu "An existing directory 'my-pugins' found. What you want to do with it?" 20 60 5 \
   "1" "KEEP existing directory \"my-plugins\" " \
   "2" "REPLACE existing directory by all source plugins" 3>&1 1>&2 2>&3);
   if [[ ${CHOICE} == "2" ]]; then
      if (whiptail --title "Confirmation" --yesno "Are you sure you want to REPLACE your existing plugins?" --defaultno 10 60 5 ); then
         echo "Renaming existing folder \"my-plugins\" to \"my-plugins.$datetime.bup\" "
         rm -rf ${INSTALL_FOLDER}/my-plugins.$datetime.bup
         mv ${INSTALL_FOLDER}/my-plugins ${INSTALL_FOLDER}/my-plugins.$datetime.bup
         INSTALL_PLUGINS=""
      fi
   fi
fi

if [ "${INSTALL_BUILD_TOOLS}" == "YES" ] ; then
   echo "Installing build tools and dependencies..."
   apt-get update
   apt-get install -y git make gcc g++ cmake pkg-config librtlsdr-dev whiptail minify xxd
fi

SCRIPT_FILE=${INSTALL_FOLDER}/start-ais.sh
if [ -e "${SCRIPT_FILE}" ] ; then
   echo "Startup script file \"${SCRIPT_FILE}\" already exists, skipping..."
else
   echo "Creating startup script file \"${SCRIPT_FILE}\""
   touch ${SCRIPT_FILE}
   chmod 777 ${SCRIPT_FILE}
   echo "Writing code to startup script file start-ais.sh"
   /bin/cat <<EOM >${SCRIPT_FILE}
#!/bin/sh
CONFIG=""
a=""
b=""
while read -r line;
   do
      a="\$line";
      b="\${a%%#*}";
      if [ -n "\${b}" ]; then
        CONFIG="\${CONFIG} \${b}";
      fi
   done < ${INSTALL_FOLDER}/aiscatcher.conf
cd ${INSTALL_FOLDER}
/usr/local/bin/AIS-catcher\${CONFIG}
EOM
   chmod +x ${SCRIPT_FILE}
fi

SERVICE_FILE=/lib/systemd/system/aiscatcher.service
if [ -e "${SERVICE_FILE}" ] ; then
   echo "Service file \"${SERVICE_FILE}\" already exists, skipping..."
else
   echo "Creating Service file \"${SERVICE_FILE}\""
   touch ${SERVICE_FILE}
   chmod 777 ${SERVICE_FILE}
   /bin/cat <<EOM >${SERVICE_FILE}
# AIS-catcher service for systemd
[Unit]
Description=AIS-catcher
Wants=network.target
After=network.target
[Service]
User=aiscat
RuntimeDirectory=aiscatcher
RuntimeDirectoryMode=0755
ExecStart=/bin/bash ${INSTALL_FOLDER}/start-ais.sh
SyslogIdentifier=aiscatcher
Type=simple
Restart=on-failure
RestartSec=30
RestartPreventExitStatus=64
Nice=-5
[Install]
WantedBy=default.target
EOM

   chmod 644 ${SERVICE_FILE}
fi
systemctl enable aiscatcher

echo "Entering install folder..."
cd ${INSTALL_FOLDER}

if [ "${DOWNLOAD}" == "YES" ] ;then
   echo "Removeing old source..."
   rm -rf AIS-catcher
   echo "Cloning source-code of AIS-catcher from Github..."
   git clone https://github.com/jvde-github/AIS-catcher.git
   cd AIS-catcher
   git config --global --add safe.directory ${INSTALL_FOLDER}/AIS-catcher
   git fetch --all
   git reset --hard origin/main
else
   echo "NO DOWNLOAD..."
   cd AIS-catcher
fi

if [ "${INSTALL_STEK_PATCHES}" == "YES" ] ;then
   echo "Patching source..."
   ../stek-aispatcher/patchstek.sh

else
   echo "No patch"
fi

echo "Build HTML..."
scripts/build-html.sh "$(grep "VERSION_DESCRIBE" Application/AIS-catcher.h | cut -d '"' -f 2 | cut -d '_' -f 1)_stek_$(date +"%Y%m%d-%H%M%S")"

rm -rf build
echo "Build..."
mkdir -p build
cd build
cmake ..
make
echo "Copying AIS-catcher binary in folder /usr/local/bin/ "
if [[ -f "${INSTALL_FOLDER}/AIS-catcher/build/AIS-catcher" ]]; then
   echo "Stoping existing aiscatcher to enable over-write"
   systemctl stop aiscatcher
   if [ $(pgrep AIS-catcher) ]; then 
      killall AIS-catcher
   fi
   echo "Copying newly built binary \"AIS-catcher\" to folder \"/usr/local/bin/\" "
   cp ${INSTALL_FOLDER}/AIS-catcher/build/AIS-catcher /usr/local/bin/AIS-catcher

elif [[ ! -f "${INSTALL_FOLDER}/AIS-catcher/build/AIS-catcher" ]]; then
   echo " "
   echo -e "\e[1;31mAIS binary was not built\e[39m"
   echo -e "\e[1;31mPlease run install script again\e[39m"
   exit
fi

if [ "${INSTALL_PLUGINS}" == "OLD" ]; then
   echo "Keeping old \"my-plugins\""
else
   echo "Copying files from Source code folder \"AIS-catcher/plugins\" to folder \"my-plugins\" "
   mkdir ${INSTALL_FOLDER}/my-plugins
   cp ${INSTALL_FOLDER}/AIS-catcher/plugins/* ${INSTALL_FOLDER}/my-plugins/
fi

if [ ! `id -u aiscat` ]; then
   echo "Creating user aiscat to run AIS-catcher"
   useradd --system aiscat
   usermod -a -G plugdev aiscat
else
   echo "User aiscat already exists. Not creating it again"
fi

echo "Assigning ownership of install folder to user aiscat"
chown aiscat:aiscat -R ${INSTALL_FOLDER}

systemctl start aiscatcher

echo " "
echo " "
echo -e "\e[32mINSTALLATION COMPLETED \e[39m"
echo -e "\e[32m=======================\e[39m"
echo -e "\e[32mPLEASE DO FOLLOWING:\e[39m"
echo -e "\e[32m=======================\e[39m"

echo -e "\e[33m(1) If on RPi you have installed AIS Dispatcher or OpenCPN,\e[39m"
echo -e "\e[33m    it should be configured to use UDP Port 10110, IP 127.0.0.1 OR 0.0.0.0\e[39m"

echo -e "\e[33m(2) Open file aiscatcher.conf by following command:\e[39m"
echo -e "\e[39m       sudo nano "${INSTALL_FOLDER}"/aiscatcher.conf \e[39m"
echo -e "\e[33m(3) In above file:\e[39m"
echo -e "\e[33m    (a) Change 00000162 in \"-d 00000162\" to actual Serial Number of AIS dongle\e[39m"
echo -e "\e[33m    (b) Change 3 in \"-p 3\" to the actual ppm correction figure of dongle\e[39m"
echo -e "\e[33m    (c) Change 38.6 in \"-gr TUNER 38.6 RTLAGC off\" to desired Gain of dongle\e[39m"
echo -e "\e[33m    (d) Add following line and replace xx.xxx and yy.yyy by actual values:\e[39m"
echo -e "\e[35m          -N STATION MyStation LAT xx.xxx LON yy.yyy \e[39m"
echo -e "\e[33m    (e) For each Site you want to feed AIS data, add a new line as follows:\e[39m"
echo -e "\e[35m          -u [URL or IP of Site] [Port Number of Site]  \e[39m"
echo -e "\e[33m    (f) Save (Ctrl+o) and  Close (Ctrl+x) file aiscatcher.conf \e[39m"
echo " "
echo -e "\e[01;31mIMPORTANT: \e[32mIf you are \e[01;31mUpgrading or Reinstalling,\e[32myour old source folder, config file & plugin folder are saved as \e[39m"
echo -e "\e[39m       "${INSTALL_FOLDER}/AIS-catcher.$datetime.bup" \e[39m"
echo -e "\e[39m       "${INSTALL_FOLDER}/aiscatcher.conf.$datetime.bup" \e[39m"
echo -e "\e[39m       "${INSTALL_FOLDER}/my-plugins.$datetime.bup" \e[39m"
echo " "
echo -e "\e[01;31m(4) REBOOT RPi ... REBOOT RPi ... REBOOT RPi \e[39m"
echo " "
echo -e "\e[01;32m(5) See the Web Interface (Map etc) at\e[39m"
echo -e "\e[39m        $(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8383 \e[39m" "\e[35m(IP-of-PI:8383) \e[39m"
echo " "
echo -e "\e[32m(6) Command to see Status\e[39m sudo systemctl status aiscatcher"
echo -e "\e[32m(7) Command to Restart\e[39m    sudo systemctl restart aiscatcher"

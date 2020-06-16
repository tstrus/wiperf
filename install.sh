#!/bin/bash
# Installer for wiperf on WLAN Pi

# Installation script log file
LOG_FILE="/var/log/wiperf_install.log"

# install dir
CLONE_DIR="/usr/share"
INSTALL_DIR="$CLONE_DIR/wiperf"
CFG_DIR="/etc/wiperf"

GITHUB_REPO="https://github.com/wifinigel/wiperf.git"
GITHUB_BRANCH='conf_pull'

install () {

  echo "(ok) Starting wiperf install process (see $LOG_FILE for details)" | tee $LOG_FILE 

  # check we can get to pypi
  curl -s --head  -m 2 --connect-timeout 2 --request GET https://pypi.org | head -n 1 | grep '200'  >> $LOG_FILE 2>&1
  if [ "$?" != '0' ]; then
    echo "Unable to reach Internet - check connection (exiting)" | tee -a $LOG_FILE 
    exit 1
  fi

  # check git is present
  echo "(ok) Checking we have git available..."
  `git --version`  >> $LOG_FILE 2>&1
  if [ "$?" != '0' ]; then
    echo "(fail) Unable to proceed as git not installed...please install with command 'apt-get install git' " | tee -a $LOG_FILE
    exit 1
  else
    echo "(ok) Git looks OK"  | tee -a $LOG_FILE
  fi

  # install the wiperf poller from PyPi - exit if errors
  echo "(ok) Installing wiperf python module (please wait)..."  | tee -a $LOG_FILE
  pip3 install wiperf_poller >> $LOG_FILE 2>&1
  if [ "$?" != '0' ]; then
      echo "(fail) pip installation of wiperf_poller failed. Exiting." | tee -a $LOG_FILE 
      exit 1
  else
      echo "(ok) wiperf_poller module python installed" | tee -a $LOG_FILE 
  fi

  # pull & install the Splunk Event collector class
  echo "(ok) Cloning the Splunk Event collector class..." | tee -a $LOG_FILE

  # take out existing dir (if there)
  rm -rf /tmp/Splunk-Class-httpevent

  git -C /tmp clone https://github.com/georgestarcher/Splunk-Class-httpevent.git >> $LOG_FILE 2>&1

  if [ "$?" != '0' ]; then
    echo "(fail) Clone of Splunk Python module failed." | tee -a $LOG_FILE
    exit 1
  else
    echo "(ok) Python Splunk module cloned OK." | tee -a $LOG_FILE
  fi 

  # Install the module
  echo "(ok) Installing the Splunk Event collector class (please wait)..." | tee -a $LOG_FILE
  pip3 install /tmp/Splunk-Class-httpevent >> $LOG_FILE 2>&1
  if [ -z "$?" ]; then
    echo "(fail) Install of Splunk Python module failed." | tee -a $LOG_FILE
    exit 1
  else
    echo "(ok) Splunk Python module installed OK." | tee -a $LOG_FILE
  fi

  # Pull in the wiperf github code
  echo "(ok) Cloning GitHub wiperf repo (please wait)..." | tee -a $LOG_FILE
  git -C $CLONE_DIR clone $GITHUB_REPO -b $GITHUB_BRANCH >> $LOG_FILE 2>&1
  if [ "$?" != '0' ]; then
    echo "(fail) Clone of GitHub repo failed." | tee -a $LOG_FILE
    exit 1
  else
    echo "(ok) Cloned OK." | tee -a $LOG_FILE
  fi

  # copy config.ini.default to $CFG_DIR
  echo "(ok) Moving config.default.ini to $CFG_DIR..." | tee -a $LOG_FILE
  mkdir -p $CFG_DIR  >> $LOG_FILE 2>&1
  mv "$INSTALL_DIR/config.default.ini" $CFG_DIR  >> $LOG_FILE 2>&1
  if [ "$?" != '0' ]; then
    echo "(fail) Copy of config.ini.default failed." | tee -a $LOG_FILE
    exit 1
  else
    echo "(ok) Copied OK." | tee -a $LOG_FILE
  fi

  # move files in ./conf to $CFG_DIR
  echo "(ok) Moving conf directory to $CFG_DIR..." | tee -a $LOG_FILE
  mv "$INSTALL_DIR/conf" $CFG_DIR  >> $LOG_FILE 2>&1
  if [ -z "$?" ]; then
    echo "(fail) Copy of conf directory failed." | tee -a $LOG_FILE
    exit 1
  else
    echo "(ok) Copied OK." | tee -a $LOG_FILE
  fi

  # copy wiperf_switcher to /usr/bin/wiperf_switcher
  echo "(ok) Moving wiperf_switcher to /usr/bin/wiperf_switcher..." | tee -a $LOG_FILE
  mv "$INSTALL_DIR/wiperf_switcher" /usr/bin/wiperf_switcher  >> $LOG_FILE 2>&1

  if [ "$?" != '0' ]; then
    echo "(fail) Copy of wiperf_switcher failed." | tee -a $LOG_FILE
    exit 1
  else
    echo "(ok) Copied OK." | tee -a $LOG_FILE
    # make sure it can be executed
    chmod 755 /usr/bin/wiperf_switcher
  fi

  echo "(ok) Install complete." | tee -a $LOG_FILE

  echo ""
  echo "================================================="
  echo "Don'tforget to modify the following files before"
  echo "switching in to wiperf mode:"
  echo ""
  echo " 1. Edit $CFG_DIR/wpa_supplicant/wpa_supplicant.conf" 
  echo "    (add WLAN info)"
  echo " 2. Copy $CFG_DIR/config.default.ini to $CFG_DIR/config.ini"
  echo " 3. Edit $CFG_DIR/config.ini for your env"
  echo "================================================="
  echo ""
}

uninstall () {
  echo "(ok) Starting wiperf uninstall process (see $LOG_FILE for details)" | tee $LOG_FILE

  # remove python modules
  echo "(ok) Removing Python modules" | tee -a $LOG_FILE
  echo "(ok) ...splunk_http_event_collector" | tee -a $LOG_FILE
  pip3 uninstall -y splunk_http_event_collector  >> $LOG_FILE 2>&1
  echo "(ok) ...wiperf_poller" | tee -a $LOG_FILE
  pip3 uninstall -y wiperf_poller  >> $LOG_FILE 2>&1

  # remove directories
  echo "(ok) Removing install dir" | tee -a $LOG_FILE
  rm -rf $INSTALL_DIR  >> $LOG_FILE 2>&1
    echo "(ok) Removing config dir" | tee -a $LOG_FILE
  rm -rf $CFG_DIR  >> $LOG_FILE 2>&1
  echo "(ok) Removing switcher script" | tee -a $LOG_FILE
  rm -f /usr/bin/wiperf_switcher  >> $LOG_FILE 2>&1

  # remove log files
  echo "(ok) Removing log files" | tee -a $LOG_FILE
  rm -f /var/log/wiperf*.log
  echo "(ok) Done"
}

case "$1" in
  -u)
        uninstall
        ;;
  -i)
        install
        ;;
  *)
        install
        ;;
esac

exit 0
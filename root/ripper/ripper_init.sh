#!/bin/bash

set -euo pipefail

chmod +x $0
chmod +x /ripper/*.sh /config/*.sh /web/web.py
# copy default script
if [[ ! -f /config/ripper.sh ]]; then
  cp /ripper/ripper.sh /config/ripper.sh
fi

TZ=${TZ:-'America/Chicago'}
NUID=${NUID:-99}
NGID=${NGID:-100}
DEBUG=${DEBUG:-"false"}
if [ 'true' == "${DEBUG,,}" ]; then
  set -xo verbose
fi

##Functions
setTimeZone(){
  [[ ${TZ} == $(cat /etc/timezone) ]] && return
  echo "Setting timezone to ${TZ}"
  ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime
  dpkg-reconfigure -fnoninteractive tzdata
}

getVersion(){
  echo "latest version: $(curl -s http://www.makemkv.com/download/ | grep -Eom1 "MakeMKV 1.[0-9]+\.[0-9]+")"
}

setTimeZone

getVersion

[[ $(id -u nobody ) -ne ${NUID:-99} ]] && echo "setting uid as ${NUID}" && usermod -u ${NUID:-99} nobody
[[ $(id -g nobody ) -ne ${NGID:-100} ]] && echo "setting gid as ${NGID}" && usermod -g ${NGID:-100} nobody

# fetching MakeMKV beta key
KEY=$(curl --silent 'https://forum.makemkv.com/forum/viewtopic.php?f=5&t=1053' | grep -oP 'T-[\w\d@]{66}')
MKV_KEY=${MKV_KEY:-${KEY}}

# copy default settings
mkdir -p /root/.MakeMKV
if [[ ! -f /config/settings.conf ]] && [[ -n ${MKV_KEY} ]]; then
  echo "app_Key = \"${MKV_KEY}\"" >/config/settings.conf
  echo "No settings.conf. writing key to file."
  cp /config/settings.conf /root/.MakeMKV/settings.conf
fi

# Updating Key if needed
if [[ $(grep -c ${MKV_KEY} /config/settings.conf) -eq 0 ]]; then
  echo "app_Key = \"${MKV_KEY}\"" >/config/settings.conf
  echo "Found settings.conf. Replacing beta key file."
  cp /config/settings.conf /root/.MakeMKV/settings.conf
fi

# permissions
chown -R nobody:users /config
chmod -R g+rw /config

chmod +x /config/ripper.sh

supervisorctl start ripper

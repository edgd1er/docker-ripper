#!/bin/bash

set -euo pipefail
# copy default script
if [[ ! -f /config/ripper.sh ]]; then
  cp /ripper/ripper.sh /config/ripper.sh
fi

DEBUG=${DEBUG:-"False"}
if [ 'true' == ${DEBUG,,} ]; then
  set -xo verbose
fi

usermod -u ${NUID:-99} nobody
usermod -g ${NGID:-100} nobody

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

#!/bin/bash

mkdir -p /config

# copy default script
if [[ ! -f /config/ripper.sh ]]; then
    cp /ripper/ripper.sh /config/ripper.sh
fi

# copy default settings
if [[ ! -f /config/settings.conf ]] && [[ ! -f /config/enter-your-key-then-rename-to.settings.conf ]]; then
    cp -f /ripper/settings.conf /config/
    mv /config/settings.conf /config/enter-your-key-then-rename-to.settings.conf
fi

# fetching MakeMKV beta key
KEY=$(curl --silent 'https://forum.makemkv.com/forum/viewtopic.php?f=5&t=1053' | grep -oP 'T-[\w\d@]{66}')

# move settings.conf, if found
mkdir -p /root/.MakeMKV
if [[ -f /config/settings.conf ]]; then
    echo "Found settings.conf. Replacing beta key file."
    cp -f /config/settings.conf /root/.MakeMKV/
elif [ -n $KEY ]; then
    echo "Using MakeMKV beta key: $KEY"
    echo app_Key = "\"$KEY"\" >/root/.MakeMKV/settings.conf
fi

makemkvcon reg

# move abcde.conf, if found
if [[ -f /config/abcde.conf ]]; then
    echo "Found abcde.conf."
    cp -f /config/abcde.conf /ripper/abcde.conf
fi

# permissions
chown -R nobody:users /config
chmod -R g+rw /config

chmod +x /config/ripper.sh

bash /config/ripper.sh &

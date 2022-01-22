[![build docker-ripper multi-arch images](https://github.com/edgd1er/docker-ripper/actions/workflows/buildPush.yml/badge.svg)](https://github.com/edgd1er/docker-ripper/actions/workflows/buildPush.yml)

[![lint docker-ripper dockerfile](https://github.com/edgd1er/docker-ripper/actions/workflows/lint.yml/badge.svg)](https://github.com/edgd1er/docker-ripper/actions/workflows/lint.yml)

![Docker Size](https://badgen.net/docker/size/edgd1er/docker-ripper?icon=docker&label=Size)
![Docker Pulls](https://badgen.net/docker/pulls/edgd1er/docker-ripper?icon=docker&label=Pulls)
![Docker Stars](https://badgen.net/docker/stars/edgd1er/docker-ripper?icon=docker&label=Stars)
![ImageLayers](https://badgen.net/docker/layers/edgd1er/docker-ripper?icon=docker&label=Layers)

current makemkvcon's version: 1.16.5

Forked from https://github.com/rix1337/docker-ripper

## Differences
* Replace phusion-baseimage with debian-stretch
* use multi stage to build makemkv (not depending on ppa updates)
* Use supervisor to run apps.
* User and group ID are settable.
* Show latest makemkv version.
* send notifications (email, pushover, pushbullet) upon completion
* added options:
   * NUID/NGID: set nobody UID/GID (chown output dir)
   * TZ: Define timezone
  

This container will detect optical disks by their type and rip them automatically.

# Output

Disc Type | Output | Tools used
---|---|---
CD | MP3 and FLAC | abcde (lame and flac)
Data-Disk | Uncompressed .ISO | ddrescue
DVD | MKV | MakeMKV
BluRay | MKV | MakeMKV

### Prerequistites

#### (1) Create the required directories, for example, in /home/yourusername. Do _not_ use sudo mkdir to achieve this.

`mkdir -p rips config`

#### (2) Find out the name(s) of the optical drive

get your drive name: 

`dmesg | egrep -i --color 'cdrom|dvd|cd/rw|writer'` 

or

`less /proc/sys/dev/cdrom/info`



## Docker run

In the command below, the paths refer to the output from your lsscsi-g command, along with your config and rips
directories. If you created /home/yourusername/config and /home/yourusername/rips then those are your paths.

```dockerfile
docker run -d \
  --name="Ripper" \
  --privileged
  -v /path/to/config/:/config:rw \
  -v /path/to/rips/:/out:rw \
  --device=/dev/sr0:/dev/sr0 \
  --device=/dev/sg0:/dev/sg0 \
  edgd1er/docker-ripper
```

```yaml
version: '3.8'
services:
  docker-ripper:
    image: edgd1er/docker-ripper
    container_name: ripper
    ports:
      - "9191:9090"
    privileged: true
    environment:
      TZ: "Europe/Paris"
      LOGIN: "toto"
      PASS: "toto"
      PREFIX: ''
      DEBUG: 'False'
      NOTIFICATION_ON: "y"
      EMAIL_SENDER: 'YOUR_EMAIL'
      EMAIL_RECIPIENTS: 'DEST_EMAIL'
      EMAIL_PASSWORD: 'YOUR_PASSWORD'
      EMAIL_SERVER: 'smtp.gmail.com'
      EMAIL_SERVER_PORT: '587'
      EMAIL_DEBUG_LEVEL: '0'
      # Push notification parameters (Pushover)
      PUSHOVER_APP_TOKEN: 'YOUR_APP_TOKEN'
      USER_KEY: 'YOUR_USER_KEY'
      # Push notification parameters (Pushbullet)
      PUSHBULLET_APP_TOKEN: 'YOUR_APP_TOKEN'
    volumes:
      - './config/:/config:rw'
      - './rips/:/out:rw'
    devices:
      - '/dev/null:/dev/sr0'
```

Other environment variables

NUID: new user id to set ownership of output files (default 99)
NGID: new group id to set ownership of output files (default 100)
TZ: optional, define TimeZone.
MVN_KEY: optional, set purchased key. if not defined the latest beta key is fetched. Delete settings.conf to force 

### Notifications

three types of notifications are available: email, pushover, pushbullet.
If EMAIL_SENDER is empty, no email is sent.
If PUSHOVER_APP_TOKEN, no pushover is sent.
If EMAIL_RECIPIENTS is empty, no pushbullet is sent.
A global toggle `SEND_NOTIFICATION` is set (y/n) to enable or disable notifications.

#### Using the web UI for logs

Add these optional parameters when running the container
````
  -p port:9090 \
  -e PREFIX=OPTIONAL_WEB_UI_PATH_PREFIX \ 
  -e USER=OPTIONAL_WEB_UI_USERNAME \ 
  -e PASS=OPTIONAL_WEB_UI_PASSWORD \
````

`USER` and `PASS` both need to be set to enable http basic auth for the web UI.
`PREFIX` can be used to set a path prefix (e.g. `/ripper-ui`. This is useful when you are running multiple services at one domain.

**To properly detect optical disk types in a docker environment this script relies on makemkvcon output.**

MakeMKV is free while in Beta, but requires a valid license key. Ripper tries to fetch the latest free beta key on
launch. Without a purchased license key Ripper may stop running at any time.

#### If you have purchased a license key to MakeMKV/Ripper:

1) define the environment variable MVN_KEY with your key.
in the commandline to start the container
```commandline
-e MVN_KEY="T-oDpQwQnTwMvNEFulk0bRciM7SWtVkY9ODCy8g8q1oHjUwZWkX0bkAPNZmCaKVNoWZv"
```
or in the docker-compose.yml file.

2) After the container is started, your settings.conf in config directory should look like this:  
```
app_Key = "T-oDpQwQnTwMvNEFulk0bRciM7SWtVkY9ODCy8g8q1oHjUwZWkX0bkAPNZmCaKVNoWZv"
```

# Docker compose

Check your device mount point before you run the container!

`docker-compose up -d`

# FAQ

### There is an error regarding 'ccextractor'

Add the following line to settings.conf

```
app_ccextractor = "/usr/local/bin/ccextractor" 
```

### How do I set ripper to do something else?

_Ripper will place a bash-file ([ripper.sh](https://github.com/edgd1er/docker-ripper/blob/master/root/ripper/ripper.sh))
automatically at /config that is responsible for detecting and ripping disks. You are completely free to modify it on
your local docker host. No modifications to this main image are required for minor edits to that file._

_Additionally, you have the option of creating medium-specific override scripts in that same directory location:_

Medium | Script Name | Purpose
--- | --- | ---
BluRay | `BLURAYrip.sh` | Overrides BluRay ripping commands in `ripper.sh` with script operation
DVD | `DVDrip.sh` | Overrides DVD ripping commands in `ripper.sh` with script operation
Audio CD | `CDrip.sh` | Overrides audio CD ripping commands in `ripper.sh` with script operation
Data-Disk | `DATArip.sh` | Overrides data disk ripping commands in `ripper.sh` with script operation

_Note that these optional scripts must be of the specified name, have executable permissions set, and be in the same
directory as `ripper.sh` to be executed._

### How do I rip from multiple drives simultaneously?

Simple: run multiple containers of this image, passing through each separate drive accordingly.

### How do I customize the audio ripping output?

_You need to edit /config/abcde.conf_

### I want another output format that requires another piece of software!

_You need to fork this image and build it yourself on docker hub. A good starting point is
the [Dockerfile](https://github.com/edgd1er/docker-ripper/blob/master/Dockerfile#L30) that includes setup instructions
for the used ripping software. If your solution works better than the current one, I will happily review your pull
request._

### MakeMKV needs an update!

_Make sure you have pulled the latest image. The image should be updated automatically as soon as MakeMKV is updated.
This has not worked reliably in the past. Just [open a new issue](https://github.com/edgd1er/docker-ripper/issues/new)
and I will trigger the build._

### Am I allowed to use this in a commercial setting?

_Yes, see [LICENSE.md](https://github.com/edgd1er/docker-ripper/blob/master/LICENSE.md)._

# Credits

- [MakeMKV build by makemkv](https://forum.makemkv.com/forum/viewtopic.php?f=3&t=224)

- [MakeMKV key/version fetcher by metalight](http://blog.metalight.dk/2016/03/makemkv-wrapper-with-auto-updater.html)

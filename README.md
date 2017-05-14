# MediaCentreInstaller
## Description
A simple, user-friendly bash script for installing media centre software using Docker on Ubuntu
It currently supports the following software:
- Sonarr (<a href="https://github.com/linuxserver/docker-sonarr">source</a>)
- Radarr (<a href="https://github.com/linuxserver/docker-radarr">source</a>)
- Deluge (<a href="https://github.com/linuxserver/docker-deluge">source</a>)
- Plex (<a href="https://github.com/linuxserver/docker-plex">source</a>)
- Jackett (<a href="https://github.com/linuxserver/docker-jackett">source</a>)
- Cardigann (<a href="https://github.com/linuxserver/docker-cardigann">source</a>)

It allows configuration for the usual media and download directories as well as allowing the option for storing important configuration locally.
It also offers the ability to configure the Dockers to use a VPN container to push the traffic through for security.
It's currently a work in progress, but if there are any issues, please post on the <a href="https://github.com/thelastparadox/mediacentreinstaller/issues">issues board</a>.

---

## Installation
```
wget https://raw.githubusercontent.com/thelastparadox/mediacentreinstaller/master/mediacentreinstaller.sh 

./mediacentreinstaller.sh
```
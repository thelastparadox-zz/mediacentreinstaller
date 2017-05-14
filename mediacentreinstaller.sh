#!/bin/sh
###########################
### Uber Install Script ###
###########################

# Setup Variables
VERSION=1.0.1
CONFIG_QUIET_MODE=true
THEME_NAME_SHORT_NAME="MEDIACENTREINSTALLER"
THEME_NAME_LONG_NAME="Media Centre Installer"
THEME_BOFLINE="[$THEME_NAME_SHORT_NAME]"
THEME_SUCCESS="[SUCCESS]"
THEME_FAILED="[FAILED]"
THEME_INSTALLED="[ALREADY INSTALLED]"
THEME_NOT_INSTALLED="[NOT INSTALLED]"
THEME_OK="[OK]"
EXISTING_DOCKERS="sonarr,radarr,deluge,vpn,jackett,cardigann,proxy"
DEFAULT_DOWNLOAD_LOCATION="/NAS/downloads"
DEFAULT_DOCKER_LOCATION="/NAS/docker"
DEFAULT_TVSHOWS_LOCATION="/NAS/video/tvshows"
DEFAULT_MOVIES_LOCATION="/NAS/video/movies"
INSTALL_COMMAND_SONARR="sudo docker run --restart=always -d --name=sonarr -p 8989:8989 -e PUID=1000 -e PGID=1000 -v /dev/rtc:/dev/rtc:ro -e TZ="Europe/London" -v "$DOCKER_LOCATION"/sonarr/config:/config -v "$TVSHOWS_LOCATION":/tv -v "$DOWNLOADS_LOCATION":/downloads -v "$DOWNLOADS_LOCATION":/NAS/downloads -v "$TVSHOWS_LOCATION":"$TVSHOWS_LOCATION" linuxserver/sonarr $QUIET_MODE"
CONTINUE=true
LOG_FILE="$(dirname $0)/${THEME_NAME_SHORT_NAME,,}-log-$(date +%Y-%m-%d).log"

# Setup Quiet Mode
if [[ CONFIG_QUIET_MODE == true ]]; then
  QUIET_MODE="> /dev/null 2>&1"
else
  QUIET_MODE=""
fi

# Intro
whiptail --title "$THEME_NAME_LONG_NAME $VERSION" --msgbox "Welcome to the $THEME_NAME_LONG_NAME. This guided installer will download, install and configure any software you choose by using the CE edition of Docker. Please click OK to continue." 12 78

# Beginning Install
echo -e "$(date +%Y-%m-%d:%H:%M:%S) $THEME_BOFLINE Beginning installation...\n" >> $LOG_FILE

# Check to see if platform is Ubuntu
OS_1="$(gawk -F= '/^NAME/{print $2}' /etc/os-release)"
OS="${OS_1//\"}"

if [[ OS -ne "Ubuntu" ]]; then
  whiptail --title "ERROR" --msgbox "Unfortunately this installer is only configured for Ubuntu at the moment." 12 78
  CONTINUE=false
  echo -e "$(date +%Y-%m-%d:%H:%M:%S) $THEME_BOFLINE OS is not compatible with installer ($OS)\n" >> $LOG_FILE
else
  echo -e "$(date +%Y-%m-%d:%H:%M:%S) $THEME_BOFLINE OS has been confirmed as Ubuntu\n" >> $LOG_FILE
fi

# Select INSTALL_CHOICES to Install
if [[ $CONTINUE == true ]]; then
  INSTALL_CHOICES=$(whiptail --title "Select Software" --checklist \
  "Select the software you would like to install..." 20 60 8 \
  "Sonarr" "TV Show Manager" ON \
  "Radarr" "Movie Manager" ON \
  "Deluge" "BitTorrent Download Manager" ON \
  "Plex" "Media Centre" ON \
  "Jackett" "Torrent Indexer" ON \
  "Cardigann" "Torrent Indexer (no longer supported)" ON \
  "Portainer" "Dahsboard for managing INSTALL_CHOICES" ON \
  3>&1 1>&2 2>&3)
  echo -e "$(date +%Y-%m-%d:%H:%M:%S) $THEME_BOFLINE Install choices are: $INSTALL_CHOICES\n" >> $LOG_FILE
fi

if [[ $CONTINUE == true && $INSTALL_CHOICES != "" ]]; then
  if (whiptail --title "Usage of VPN" --yesno "Would you like to run all traffic via a VPN?." 8 78); then
    VPN="yes"
    INSTALL_CHOICES="${INSTALL_CHOICES} VPN"
    echo -e "$(date +%Y-%m-%d:%H:%M:%S) $THEME_BOFLINE VPN use: yes\n" >> $LOG_FILE
  else
    VPN="no"
  fi
fi

if [[ $CONTINUE == true && $INSTALL_CHOICES != "" ]]; then
  DOCKER_LOCATION=$(whiptail --inputbox "Where would you like your docker config to live?" 8 78 "$DEFAULT_DOCKER_LOCATION" --title "Docker Config location" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then
    CONTINUE=false
    echo -e "$(date +%Y-%m-%d:%H:%M:%S) $THEME_BOFLINE User did not confirm Docker config location\n" >> $LOG_FILE
  else
    echo -e "$(date +%Y-%m-%d:%H:%M:%S) $THEME_BOFLINE Docker Config Location\n" >> $LOG_FILE
  fi
fi

if [[ $CONTINUE == true && $INSTALL_CHOICES != "" ]]; then
  DOWNLOADS_LOCATION=$(whiptail --inputbox "Where would you like your downloads to go?" 8 78 "$DEFAULT_DOWNLOAD_LOCATION" --title "File download location" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then
    CONTINUE=false
  fi
fi

if [[ $CONTINUE == true && $INSTALL_CHOICES != "" && $INSTALL_CHOICES == *"Radarr"* ]]; then
  MOVIES_LOCATION=$(whiptail --inputbox "Where would you like your Movies to live?" 8 78 "$DEFAULT_MOVIES_LOCATION" --title "Movies location" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then
    CONTINUE=false
  fi
fi

if [[ $CONTINUE == true && $INSTALL_CHOICES != "" && $INSTALL_CHOICES == *"Sonarr"* ]]; then
  TVSHOWS_LOCATION=$(whiptail --inputbox "Where would you like your TV Shows to live?" 8 78 "$DEFAULT_TVSHOWS_LOCATION" --title "TV Shows location" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ "$exitstatus" = 1 ]]; then
    CONTINUE=false
  fi
fi

if [[ $CONTINUE == true && $INSTALL_CHOICES != "" ]]; then
  
    ##{ # Start Progress Guage

      # Install Step 1: Check to see if Docker is installed
      sleep 0.5
      echo -e "XXX\n0\nInstalling docker... \nXXX"

      docker -v > DOCKER_INSTALLED

      if [[ $DOCKER_INSTALLED == *"not installed"* ]]; then
        # Install Docker
        echo -e "$THEME_NOT_INSTALLED\n" >> $LOG_FILE
        echo -e "$THEME_BOFLINE Installing Docker...\n" >> $LOG_FILE
        sudo apt-get update && sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual && sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install docker
      else
        echo -e "$THEME_INSTALLED\n" >> $LOG_FILE
      fi

      # Install Step 2: Stop any existing dockers
      sleep 0.5
      echo -e "XXX\n10\nStopping any existing dockers... \nXXX"

      IFS=', ' read -r -a EXISTING_DOCKERS <<< "$EXISTING_DOCKERS"
      for i in "${EXISTING_DOCKERS[@]}"
      do
         # do whatever on $i
         if [[ "$(docker inspect --format=\"{{.State.Running}}\" ${i,,} 2> /dev/null)" == true ]]; then
            echo -ne "$(date +%Y-%m-%d:%H:%M:%S) $THEME_BOFLINE Stopping $i..."  >> $LOG_FILE
            sudo docker rm --force "${i,,}" > /dev/null
            echo -e "$THEME_OK\n"
         fi
      done

      ## Begin processing choices
      #IFS=' ' read -r -a install_choices <<< "$INSTALL_CHOICES"
      #for install_choice in "${INSTALL_CHOICES[@]}"
      #do

      #done

      # Check if the user wants to use a VPN
      if [[ $VPN="yes" ]]; then
          echo -ne "$THEME_BOFLINE Starting VPN install..."
          sudo docker run -d -it --restart=always --cap-add=NET_ADMIN --device /dev/net/tun --name vpn -v "$DOCKER_LOCATION"/openvpn:/vpn dperson/openvpn-client -fd > INIT_ERROR       

          if [[ $INIT_ERROR == *"Error"* ]]; then
             echo -e "$THEME_FAILED"
             echo -e "$THEME_BOFLINE ERROR: $INIT_ERROR"
          else
             echo -e "$THEME_SUCCESS"
          fi
      fi
      # Check if user wants to use Sonarr
      if [[ $INSTALL_CHOICES == *"Sonarr"* ]]; then
         echo -ne "$THEME_BOFLINE Starting Sonarr install..."
         if [[ $VPN == "yes" ]]; then
            sudo docker run --restart=always -d --name=sonarr -p 8989:8989 -e PUID=1000 -e PGID=1000 -v /dev/rtc:/dev/rtc:ro -e TZ="Europe/London" -v "$DOCKER_LOCATION"/sonarr/config:/config -v "$TVSHOWS_LOCATION":/tv -v "$DOWNLOADS_LOCATION":/downloads -v "$DOWNLOADS_LOCATION":/NAS/downloads -v "$TVSHOWS_LOCATION":"$TVSHOWS_LOCATION" linuxserver/sonarr > INIT_ERROR      
          else
           # Install docker including port numbers without using VPN (To-do)
           echo "Unfinished code..."
         fi
         if [[ $INIT_ERROR == *"Error"* ]]; then
           echo -e "$THEME_FAILED"
           echo echo -e "$THEME_BOFLINE ERROR: $INIT_ERROR"
         else
            echo -e "$THEME_SUCCESS"
         fi
      fi
      # Check if user wants to use Radarr
      if [[ $INSTALL_CHOICES == *"Sonarr"* ]]; then
         echo -ne "$THEME_BOFLINE Starting Radarr install..."
         if [[ $VPN == "yes" ]]; then
            sudo docker run -d --restart=always --name=radarr -v "$DOCKER_LOCATION"/radarr/config:/config -v "$DOWNLOADS_LOCATION":/downloads -v "$MOVIES_LOCATION":/movies -e PGID=1000 -e PUID=1000 -e TZ="Europe/London" -v /dev/rtc:/dev/rtc:ro -p 7878:7878 linuxserver/radarr > INIT_ERROR
          else
           # Install docker including port numbers without using VPN (To-do)
           echo "Unfinished code..."
         fi
         if [[ $INIT_ERROR == *"Error"* ]]; then
           echo -e "$THEME_FAILED"
           echo echo -e "$THEME_BOFLINE ERROR: $INIT_ERROR"
         else
            echo -e "$THEME_SUCCESS"
         fi
      fi
      # Check if user wants to use Deluge
      if [[ $INSTALL_CHOICES == *"Deluge"* ]]; then
         echo -ne "$THEME_BOFLINE Starting Deluge install..."
         if [[ $VPN == "yes" ]]; then
            sudo docker run -d --restart=always --name=deluge --net=container:vpn -e PUID=1000 -e PGID=1000 -e TZ=Europe/London -v "$DOWNLOADS_LOCATION":/downloads -v "$DOCKER_LOCATION"/deluge:/config linuxserver/deluge  > INIT_ERROR
  	     else
           # Install docker including port numbers without using VPN (To-do)
           echo "Unfinished code..."
         fi
         if [[ $INIT_ERROR == *"Error"* ]]; then
           echo -e "$THEME_FAILED"
           echo echo -e "$THEME_BOFLINE ERROR: $INIT_ERROR"
         else
            echo -e "$THEME_SUCCESS"
         fi
      fi
      # Check if the user wants to use Cardigann
      if [[ $INSTALL_CHOICES == *"Cardigann"* ]]; then
         echo -ne "$THEME_BOFLINE Starting Cardigann install..."
         if [[ $VPN == "yes" ]]; then
           sudo docker run -d --restart=always --name=cardigann --net=container:vpn -v "$DOCKER_LOCATION"/cardigann:/config -e PGID=1000 -e PUID=1000 linuxserver/cardigann > INIT_ERROR
         else
           # Install docker including port numbers without using VPN (To-do)
           echo "Unfinished code..."
         fi
         if [[ $INIT_ERROR == *"Error"* ]]; then
           echo -e "$THEME_FAILED"
           echo echo -e "$THEME_BOFLINE ERROR: $INIT_ERROR"
         else
            echo -e "$THEME_SUCCESS"
         fi

      fi
      # Check if the user wants to use Jackett
      if [[ $INSTALL_CHOICES == *"Jackett"* ]]; then
         echo -ne "$THEME_BOFLINE Starting Jackett install..."
         if [[ $VPN == "yes" ]]; then
           INIT_ERROR="$(sudo docker run --restart=always -d --name=jackett --net=container:vpn -v /etc/localtime:/etc/localtime:ro -v "$DOCKER_LOCATION"/jackett:/config -v "$DOWNLOADS_LOCATION":/downloads -e PUID=1000 -e PGID=1000 -e TZ="Europe/London" linuxserver/jackett $QUIET_MODE)"
         else
           # Install docker including port numbers without using VPN (To-do)
           echo "Unfinished code..."
         fi
         if [[ $INIT_ERROR == *"Error"* ]]; then
           echo -e "$THEME_FAILED"
           echo echo -e "$THEME_BOFLINE ERROR: $INIT_ERROR"
         else
            echo -e "$THEME_SUCCESS"
         fi

      fi
      # Install Proxy Server for accessing VPN INSTALL_CHOICES
      if [[ $VPN="yes" ]]; then
          echo -ne "$THEME_BOFLINE Starting Proxy install..."
          sudo docker run -it --name proxy -p 80:80 -p 443:443 -p 9117:9117 --link vpn:deluge --link vpn:jackett --link vpn:cardigann --restart=always -v "$DOCKER_LOCATION"/nginx/default.conf:/etc/nginx/conf.d/default.conf -d dperson/nginx > INIT_ERROR
          if [[ $INIT_ERROR == *"Error"* ]]; then
             echo -e "$THEME_FAILED"
             echo -e "$THEME_BOFLINE ERROR: $INIT_ERROR"
          else
             echo -e "$THEME_SUCCESS"
          fi
      fi
    ##} | whiptail --title "Installation" --gauge "Please wait while installing software..." 6 60 0
else
    echo -e "$THEME_BOFLINE Exiting without installing."
fi
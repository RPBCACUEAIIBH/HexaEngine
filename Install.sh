#! /bin/bash

# Finding roots
PWDir="$(pwd)"
cd $(cd "$(dirname "$0")"; pwd -P)
OwnDir="$(pwd)"
cd "$PWDir"

# Variables
MasterIP=""

# Functions
function Common
{
  if [[ ! -d "/home/hexaengine" && -z $(grep hexaengine /etc/group) ]]
  then
    # Set up homedir user, and SSH key.
    useradd -m hexaengine
    mkdir "/home/hexaengine/.ssh"
    mkdir "/home/hexaengine/.ssh/id-rsa"
    touch "/home/hexaengine/.ssh/authorized_keys"
    chmod -R 700 "/home/hexaengine/.ssh"
    chown -R hexaengine:hexaengine "/home/hexaengine/.ssh"
    OwnIP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    sudo -u hexaengine ssh-keygen -t rsa -f "/home/hexaengine/.ssh/$OwnIP" -N ""
  else
    echo "Error hexa engine was installed before attempting to clean it up!"
    userdel -r hexaengine
    exit
  fi
}

function Master
{
  #finish setting up SSH key
  mv "/home/hexaengine/.ssh/$OwnIP.pub" "/home/hexaengine/.ssh/Master.pub"
  mv "/home/hexaengine/.ssh/$OwnIP" "/home/hexaengine/.ssh/id-rsa/Master"
  chown -R hexaengine:hexaengine "/home/hexaengine/.ssh"
  clear
  echo "Please set a password for hexaengine.(You will need this for for adding servers to the cluster...)"
  passwd hexaengine
  cp -aR "$OwnDir/MasterServer" "/home/hexaengine/HexaEngine"
}

function Slave
{
  #finish setting up SSH key
  clear
  echo "Moving ssh key to Master server. Please provide the password for your Master server.(for user hexaengine)"
  scp "/home/hexaengine/.ssh/$OwnIP.pub" "hexaengine@$MasterIP:.ssh/$OwnIP.pub"
  clear
  echo "Setting authorized key on Master server. Please provide the password for your Master server(for user hexaengine)."
  ssh hexaengine@$MasterIP "cat /home/hexaengine/.ssh/$OwnIP.pub >> /home/hexaengine/.ssh/authorized_keys && rm /home/hexaengine/.ssh/$OwnIP.pub"
  mv  "/home/hexaengine/.ssh/$OwnIP.pub" "/home/hexaengine/.ssh/Slave.pub"
  mv "/home/hexaengine/.ssh/$OwnIP" "/home/hexaengine/.ssh/id-rsa/Slave"
  echo "Setting up reverse access."
  chown -R hexaengine:hexaengine "/home/hexaengine/.ssh"
  sudo -u hexaengine scp -i "/home/hexaengine/.ssh/id-rsa/Slave" "$MasterIP:.ssh/Master.pub" "/home/hexaengine/.ssh/Master.pub"
  cat "/home/hexaengine/.ssh/Master.pub" >> "/home/hexaengine/.ssh/authorized_keys"
  rm "/home/hexaengine/.ssh/Master.pub"
  echo "Copying files..."
  cp -aR "$OwnDir/SlaveServer" "/home/hexaengine/HexaEngine"
}

# Execution
if [[ $(whoami) != "root" ]]
then
  echo "Must run as root! Aborting..."
  exit
fi
read -p "Is this a Master of Slave server?(M/S): " MS
if [[ $MS == [Mm]* ]]
then
  Common
  Master
elif [[ $MS == [Ss]* ]]
then
  clear
  read -p "Please provide IP address for the Master server?: " MasterIP
  Common
  Slave
else
  echo "Aborting..."
fi

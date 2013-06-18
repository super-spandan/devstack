#!/bin/bash

# gen-local.sh generates localrc for devstack. It's an interactive script, and
# supports the following options:
#   -a) Creates loclrc for compute nodes.

set -e

function interfaces {
  ip link show | grep -iv LOOPBACK | grep '^[0-9]:\s' | cut -d " " -f 2 |\
    cut -d ":" -f 1
}

function interface_count {
  interfaces | wc -l
}

function ip_address {
  ip addr show $1 | grep "inet\s"  | sed "s/^\s\+//g" | cut -d " " -f 2 |\
    cut -d "/" -f 1
}

function sanity_check {
  if [ ! -f $PWD/stack.sh ]; then
    echo "Run this script from devstack's root: sample/of/local.sh"
    exit 1
  fi

  INTS=$(interface_count)
  if [[ $INTS < 1 ]]; then
    echo "You have less than 2 interfaces. This script needs at least two\
      network interfaces."
    exit 1
  fi
}

function interface_exists {
  ip addr show $1
}

sanity_check

OF_DIR=`dirname $0`

AGENT=0

while getopts ":a" opt; do
  case $opt in
    a)
      echo "Creating localrc for agent."
      AGENT=1
      ;;
  esac
done


echo "Please enter a password (this is going to be used for all services):"
read PASSWORD

echo "Which interface should be used for host (ie, "$(interfaces)")?"
read HOST_INT

if ! interface_exists $HOST_INT; then
  echo "There is no interface "$HOST_INT
  exit 1
fi

echo "Which interface should be used for vm connection (ie, "$(interfaces)")?"
read FLAT_INT

if ! interface_exists $FLAT_INT; then
  echo "There is no interface "$FLAT_INT
  exit 1
fi

HOST_IP=$(ip_address eth0)
echo "What's the ip address of this machine? [$HOST_IP]"
read HOST_IP_READ
if [ $HOST_IP_READ ]; then
  HOST_IP=$HOST_IP_READ
fi

PUBLIC_IP=$HOST_IP
echo "What is the public host address for services endpoints? [$HOST_IP]"
read PUBLIC_IP_READ

if [ $PUBLIC_IP_READ ]; then
  PUBLIC_IP=$PUBLIC_IP_READ
fi

FLOATING_RANGE=10.10.10.100
echo "What is the floating range? [$FLOATING_RANGE]"
read FLOATING_RANGE_READ
if [ $FLOATING_RANGE_READ ]; then
  FLOATING_RANGE=$FLOATING_RANGE_READ
fi

SWIFT_DISK_SIZE=5000000
echo "What is the loopback disk size for Swift? [$SWIFT_DISK_SIZE]"
read SWIFT_DISK_SIZE_READ
if [ $SWIFT_DISK_SIZE_READ ]; then
  SWIFT_DISK_SIZE=$SWIFT_DISK_SIZE_READ
fi


echo "Would you like to use OpenFlow? ([n]/y)"
read USE_OF

Q_PLUGIN=openvswitch
if [[ "$USE_OF" == "y" ]]; then
  echo "This version supports only Ryu."
  Q_PLUGIN=ryu
fi

if [[ $AGENT == 0 ]]; then

  PUBLIC_INT=$HOST_INT
  echo "Which interface should be used for public connnections [$HOST_INT]?"
  read PUBLIC_INT_READ

  if [ $PUBLIC_INT_READ ]; then 

    if ! interface_exists $PUBLIC_INT_READ; then

      echo "There is no interface "$PUBLIC_INT_READ
      exit 1

    fi

    PUBLIC_INT=$PUBLIC_INT_READ

  fi

  cp $OF_DIR/ctrl-localrc localrc
  if [[ $USE_OF == "y" ]]; then
    sed -i -e 's/RYU_ENABLED_//g' localrc
  else
    sed -i -e 's/RYU_ENABLED_/#/g' localrc
  fi

  sed -i -e 's/\${HOST_IP_IFACE}/'$HOST_INT'/g' localrc
  sed -i -e 's/\${FLAT_INTERFACE}/'$FLAT_INT'/g' localrc
  sed -i -e 's/\${PUBLIC_INTERFACE}/'$PUBLIC_INT'/g' localrc
  sed -i -e 's/\${HOST_IP}/'$HOST_IP'/g' localrc
  sed -i -e 's/\${PUBLIC_SERVICE_HOST}/'$PUBLIC_IP'/g' localrc
  sed -i -e 's/\${FLOATING_RANGE}/'$FLOATING_RANGE'/g' localrc
  sed -i -e 's/\${PASSWORD}/'$PASSWORD'/g' localrc
  sed -i -e 's/\${Q_PLUGIN}/'$Q_PLUGIN'/g' localrc
  sed -i -e 's/\${RYU_HOST}/'$HOST_IP'/g' localrc
  sed -i -e 's/\${SWIFT_DISK_SIZE}/'$SWIFT_DISK_SIZE'/g' localrc

  echo "localrc generated for the controller node."
else
  echo "What's the controller's ip address?"
  read CTRL_IP

  cp $OF_DIR/agent-localrc localrc

  if [[ $USE_OF == "y" ]]; then
    sed -i -e 's/RYU_ENABLED_//g' localrc
  else
    sed -i -e 's/RYU_ENABLED_/#/g' localrc
  fi

  sed -i -e 's/\${CONTROLLER_HOST}/'$CTRL_IP'/g' localrc
  sed -i -e 's/\${FLAT_INTERFACE}/'$FLAT_INT'/g' localrc
  sed -i -e 's/\${HOST_IP}/'$HOST_IP'/g' localrc
  sed -i -e 's/\${PASSWORD}/'$PASSWORD'/g' localrc
  sed -i -e 's/\${Q_PLUGIN}/'$Q_PLUGIN'/g' localrc
  sed -i -e 's/\${RYU_HOST}/'$CTRL_IP'/g' localrc

  echo "localrc generated for a compute node."
fi

echo "Would you like to use Syslog?[y/n]"
read SYSLOG
if [[ "$SYSLOG" == "n" ]] ; then 
  	sed -i -e 's/\SYSLOG=True/SYSLOG=False/g' localrc
else 

  echo "Would you like syslog to log to a remote server?[y/n]"
  read REMOTE_SYSLOG_SERVER
  if [[ "$REMOTE_SYSLOG_SERVER" == "n" ]] ; then 
  	sed -i -e 's/\REMOTE_SYSLOG_SERVER=True/REMOTE_SYSLOG_SERVER=False/g' localrc
  else  
      
      echo "What is the IP Address of the remote server you would like to log to? i.e 129.97.119.133" 
      read SYSLOG_SERVER_IP
      if [[ $SYSLOG_SERVER_IP ]] ; then 
      	 echo "Changing syslog ip addri to $SYSLOG_SERVER_IP"
          sed -i -e 's/\${SYSLOG_SERVER_IP}/'$SYSLOG_SERVER_IP'/g' localrc  
      fi
      
      echo "What port would you like to use for the remote syslog server?"
      read  SYSLOG_SERVER_PORT
      if [[ $SYSLOG_SERVER_PORT ]] ; then 
          sed -i -e 's/\${SYSLOG_SERVER_PORT}/'$SYSLOG_SERVER_PORT'/g' localrc  
      fi
      
      echo "What protocol would you like to transmit the logs to the syslog server? [TCP/UDP]"
      read SYSLOG_PROTOCOL
      if [[ $SYSLOG_PROTOCOL ]] ; then
          sed -i -e 's/\${SYSLOG_PROTOCOL}/'$SYSLOG_PROTOCOL'/g' localrc  
      fi
  fi 

fi

echo "Now run ./stack.sh"



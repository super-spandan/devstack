#/usr/bin/env bash

# Keep track of the devstack directory
TOP_DIR=$(cd $(dirname "$0") && pwd)

source $TOP_DIR/functions

SCREEN_NAME=ovs
# Check to see if we are already running DevStack
if type -p screen >/dev/null && screen -ls | egrep -q "[0-9].$SCREEN_NAME"; then
    echo "You are already running a install_ovs.sh session."
    echo "To rejoin this session type 'screen -x $SCREEN_NAME'."
    exit 1
fi

if [ -z "$SCREEN_HARDSTATUS" ]; then
    SCREEN_HARDSTATUS='%{= .} %-Lw%{= .}%> %n%f %t*%{= .}%+Lw%< %-=%{g}(%{d}%H/%l%{g})'
fi

# Create a new named screen to run processes in
screen -d -m -S $SCREEN_NAME -t shell -s /bin/bash
sleep 1
# Set a reasonable status bar
screen -r $SCREEN_NAME -X hardstatus alwayslastline "$SCREEN_HARDSTATUS"

ENABLED_SERVICES=openvswitch
kernel_version=`cat /proc/version | cut -d " " -f3`
screen_it openvswitch "sleep 10; sudo apt-get install -y make fakeroot dkms openvswitch-switch openvswitch-datapath-dkms linux-headers-$kernel_version"

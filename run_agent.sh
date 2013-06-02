#!/bin/bash

# Keep track of the devstack directory
TOP_DIR=$(cd $(dirname "$0") && pwd)

# Import common functions
source $TOP_DIR/functions
source $TOP_DIR/stackrc
source $TOP_DIR/localrc
source $TOP_DIR/lib/nova
source $TOP_DIR/lib/glance
source $TOP_DIR/lib/cinder
source $TOP_DIR/lib/quantum

HORIZON_DIR=$DEST/horizon
OPENSTACKCLIENT_DIR=$DEST/python-openstackclient
NOVNC_DIR=$DEST/noVNC
SWIFT_DIR=$DEST/swift
SWIFT3_DIR=$DEST/swift3
SWIFTCLIENT_DIR=$DEST/python-swiftclient
QUANTUM_DIR=$DEST/quantum
QUANTUM_CLIENT_DIR=$DEST/python-quantumclient
RYU_DIR=$DEST/ryu

AGENT_BINARY="$QUANTUM_DIR/bin/quantum-ryu-agent"
AGENT_DHCP_BINARY="$QUANTUM_DIR/bin/quantum-dhcp-agent"

AGENT_L3_BINARY="$QUANTUM_DIR/bin/quantum-l3-agent"
Q_L3_CONF_FILE=/etc/quantum/l3_agent.ini

Q_CONF_FILE=/etc/quantum/quantum.conf
Q_DHCP_CONF_FILE=/etc/quantum/dhcp_agent.ini

Q_PLUGIN_CONF_PATH=etc/quantum/plugins/ryu
Q_PLUGIN_CONF_FILENAME=ryu.ini
Q_PLUGIN_CONF_FILE=$Q_PLUGIN_CONF_PATH/$Q_PLUGIN_CONF_FILENAME

# FlowVisor Config File for Default Ryu Control
RYU_FV_CONFIG=${RYU_FV_CONFIG:-/usr/etc/flowvisor/fv_config.json}

RYU_CONF_DIR=/etc/ryu
RYU_CONF=$RYU_CONF_DIR/ryu.conf

NOVA_CONF_DIR=/etc/nova
NOVA_CONF=/etc/nova/nova.conf
NOVA_BIN_DIR=$DEST/nova/bin

BM_CONF=/etc/nova-bm
BEE2_CONF=/etc/nova-bee2

BM_PXE_INTERFACE=${BM_PXE_INTERFACE:-eth1}
BM_PXE_PER_NODE=`trueorfalse False $BM_PXE_PER_NODE`
TFTPROOT=$DEST/tftproot

DNSMASQ_PID=/dnsmasq.pid
if [ -f "$DNSMASQ_PID" ]; then
    sudo kill `cat "$DNSMASQ_PID"`
    sudo rm "$DNSMASQ_PID"
fi

NL=`echo -ne '\015'`

SCREEN_NAME=${SCREEN_NAME:-stack}
# Check to see if we are already running DevStack
if type -p screen >/dev/null && screen -ls | egrep -q "[0-9].$SCREEN_NAME"; then
    echo "You are already running a stack.sh session."
    echo "To rejoin this session type 'screen -x stack'."
    echo "To destroy this session, type './unstack.sh'."
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

echo test  n-cpu "cd $NOVA_DIR && sg libvirtd $NOVA_BIN_DIR/nova-compute"
echo test  n-crt "cd $NOVA_DIR && $NOVA_BIN_DIR/nova-cert"
echo test  n-net "cd $NOVA_DIR && $NOVA_BIN_DIR/nova-network"
echo test  n-sch "cd $NOVA_DIR && $NOVA_BIN_DIR/nova-scheduler --config-dir=$BM_CONF $NL"
echo test  n-novnc "cd $NOVNC_DIR && ./utils/nova-novncproxy --config-file $NOVA_CONF --web ."
echo test  n-xvnc "cd $NOVA_DIR && ./bin/nova-xvpvncproxy --config-file $NOVA_CONF"
echo test  n-cauth "cd $NOVA_DIR && ./bin/nova-consoleauth"
echo test  g-api "cd $GLANCE_DIR; $GLANCE_BIN_DIR/glance-api --config-file=$GLANCE_CONF_DIR/glance-api.conf"
echo test  c-api "cd $CINDER_DIR && $CINDER_BIN_DIR/cinder-api --config-file $CINDER_CONF"
echo test  c-vol "cd $CINDER_DIR && $CINDER_BIN_DIR/cinder-volume --config-file $CINDER_CONF"
echo test  c-sch "cd $CINDER_DIR && $CINDER_BIN_DIR/cinder-scheduler --config-file $CINDER_CONF"
echo test  n-vol "cd $NOVA_DIR && $NOVA_BIN_DIR/nova-volume"
echo test  ryu "cd $RYU_DIR && $RYU_DIR/bin/ryu-manager --flagfile $RYU_CONF --app_lists ryu.app.rest,ryu.app.tr-edge-isolation"
echo test  n-api "cd $NOVA_DIR && $NOVA_BIN_DIR/nova-api"
echo test  q-svc "cd $QUANTUM_DIR && python $QUANTUM_DIR/bin/quantum-server --config-file $Q_CONF_FILE --config-file /$Q_PLUGIN_CONF_FILE"
echo test  q-dhcp "python $AGENT_DHCP_BINARY --config-file $Q_CONF_FILE --config-file=$Q_DHCP_CONF_FILE"
echo test  q-l3 "python $AGENT_L3_BINARY --config-file $Q_CONF_FILE --config-file=$Q_L3_CONF_FILE"
echo test  q-agt "python $AGENT_BINARY --config-file $Q_CONF_FILE --config-file /$Q_PLUGIN_CONF_FILE"
echo test  fv "cd ~ && sudo flowvisor -l $RYU_FV_CONFIG"

echo test screen_it  q-agt "python $AGENT_BINARY --config-file $Q_CONF_FILE --config-file /$Q_PLUGIN_CONF_FILE"
echo test screen_it  n-novnc "cd $NOVNC_DIR && ./utils/nova-novncproxy --config-file $NOVA_CONF --web ."
echo test screen_it  n-cpu "cd $NOVA_DIR && sg libvirtd \"$NOVA_BIN_DIR/nova-compute --config-dir=$BM_CONF_DIR\" $NL"

screen_it  q-agt "python $AGENT_BINARY --config-file $Q_CONF_FILE --config-file /$Q_PLUGIN_CONF_FILE"
sleep 2
screen_it  n-novnc "cd $NOVNC_DIR && ./utils/nova-novncproxy --config-file $NOVA_CONF --web ."
sleep 2
screen_it  n-cpu "cd $NOVA_DIR && sg libvirtd \"$NOVA_BIN_DIR/nova-compute --config-dir=$NOVA_CONF_DIR\" $NL"


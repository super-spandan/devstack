
#Allows case insensitive string comparisons
shopt -s nocasematch 

has_rsys=`sudo dpkg --get-selections | grep rsyslog | grep install`
if [[ $has_rsys = "" ]] ; then 
    echo Installing rsyslog
    sudo apt-get install rsyslog
fi    
   
echo "Would you like to use syslog to log to remote server? [y/n]"
read log_to_remote
if [[  log_to_remote != "n" ]] ; then 
    echo Please enter the IP address of the remote server
    read syslog_server_ipaddr
    echo Please enter the port
    read syslog_server_port
    echo "Please enter the protocol [TCP/UDP]"
    read syslog_server_protocol
    
    if [[ "$syslog_server_protocol" != "UDP" ]]; then 
        log_directive="*.info @@$syslog_server_ipaddr:$syslog_server_port"
    else
        log_directive="*.info @$syslog_server_ipaddr:$syslog_server_port"
    fi
fi

echo "Generating long hostname"

if [[ $OS_REGION_NAME ]]; then 
    region_name=$OS_REGION_NAME 
elif [[ -f localrc && `grep "REGION_NAME" localrc` ]]; then
    region_name=`grep REGION_NAME localrc | awk '{split($0, array, "=")} END{print array[2]}'`
else
   echo "Can't determine region name. Enter region name to prepend"
   read region_name
fi

if [[ $region_name ]]; then 
    localhostname="$region_name-$HOSTNAME"
else
    localhostname=$HOSTNAME
fi

echo "Using hostname $localhostname ; If you would like to use another name, enter it."
read new_hostname
if [[ $new_hostname ]]; then
    localhostname=$new_hostname
fi

rsysconf_path="/etc/rsyslog.conf"
#Make a copy of rsyslog.conf
if [[ -f $rsysconf_path && -f "$rsysconf_path.orig" ]] ; then 
    sudo cp $rsysconf_path "$rsysconf_path.orig"  
fi

has_name=`grep LocalHostName $rsysconf_path | grep $localhostname`
if [[ $has_name = "" ]]; then 
    sudo cat<<EOF | sudo tee -a $rsysconf_path
\$LocalHostName $localhostname
EOF

fi

has_logd=`grep "$log_directive" $rsysconf_path`

if [[ $has_logd = "" ]]; then 
    sudo cat<<EOF | sudo tee -a $rsysconf_path
$log_directive    
EOF

fi

sudo service rsyslog restart 

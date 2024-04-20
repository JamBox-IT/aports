#!/bin/sh
#. /etc/os-release
#. /etc/jambox/jambox-release
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
JAMBOX_RELEASE=`awk -F= '$1=="JAMBOX_RELEASE" { print $2 ;}' /etc/jambox/jambox-release`
PRETTY_NAME=`awk -F= '$1=="PRETTY_NAME" { print $2 ;}' /etc/os-release | tr -d '"'`
VERSION_ID=`awk -F= '$1=="VERSION_ID" { print $2 ;}' /etc/os-release`
UPTIME_DAYS=$(expr `cat /proc/uptime | cut -d '.' -f1` % 31556926 / 86400)
UPTIME_HOURS=$(expr `cat /proc/uptime | cut -d '.' -f1` % 31556926 % 86400 / 3600)
UPTIME_MINUTES=$(expr `cat /proc/uptime | cut -d '.' -f1` % 31556926 % 86400 % 3600 / 60)
cat > /etc/motd << EOF
              ____.             __________               
             |    |____    _____\______   \ _______  ___    
             |    \__  \  /     \|    |  _//  _ \  \/  /    
         /\__|    |/ __ \|  C D  \    |   (  <_> >    <    
         \________(____  /__|_|  /______  /\____/__/\_ \   
                       \/      \/       \/            \/   
%+++++++++++++++++++++++++++++++ SERVER INFO ++++++++++++++++++++++++++++++++%
%   IT JamBox Edition v.$JAMBOX_RELEASE                                              %
        Name: `hostname`
        Uptime: $UPTIME_DAYS days, $UPTIME_HOURS hours, $UPTIME_MINUTES minutes
        CPU: `cat /proc/cpuinfo | grep 'Model' | head  -1 | cut -d':' -f2`
        Memory: `free -m | head -n 2 | tail -n 1 | awk {'print  $2'}`M
        Swap: `free -m | tail -n 1 | awk {'print $2'}`M Disk: `df -h / | awk  '{ a = $2 } END { print a }'`

        Kernel: `uname -r`
        Distro: $PRETTY_NAME 
        Version $VERSION_ID

        CPU Load: `cat /proc/loadavg | awk '{print $1 ", " $2 ", " $3}'`
        Free Memory: `free -m | head -n 2 | tail -n 1 | awk {'print $4'}`M
        Free Swap: `free -m | tail -n 1 | awk {'print $4'}`M
        Free Disk: `df -h / | awk '{ a =  $2 } END { print a }'`

        eth0 Address: `ifconfig eth0 | grep "inet addr" |  awk -F: '{print $2}' | awk '{print $1}'`
        usb0 Address: `ifconfig usb0 | grep "inet addr" |  awk -F: '{print $2}' | awk '{print $1}'`
%   jb-help - For available commands                                         %
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%
EOF


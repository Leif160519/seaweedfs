#!/bin/bash
#检测weed-mount服务是否启动
A=`ps -C weed --no-header | wc -l`
if [ $A -eq 0 ];then
    systemctl start ${weed-server}.service       #启动所有weed服务
    sleep 2
    if [ $A -eq 0 ];then    #weed-mount重启失败，则停掉keepalived服务
        kill `ps -e | grep keepalived | cut -d "?" -f 1 | awk '{print $1}'`
    fi
fi

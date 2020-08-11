#!/bin/bash
#创建一千万空文件
mkdir /seaweedfs/mount/1
for((x=1;x<=1000;x++))
{
    mkdir -p /seaweedfs/mount/1/${x}
    for((y=1;y<=100;y++))
    {
        mkdir -p /seaweedfs/mount/1/${x}/${y}
        echo "正在创建/seaweedfs/mount/1/${x}/${y}"
        touch /seaweedfs/mount/1/${x}/${y}/{001..100}
    }
}

exit

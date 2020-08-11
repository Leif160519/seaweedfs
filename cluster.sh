#!/bin/bash
ip=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | grep -v 172 | cut -d '/' -f1 | head -1`
# 单节点:3 master(9331-9333) + 3 volume(8081-8083) + 2 filer(8801-8802)

#将二进制文件复制到指定目录
cp bin/weed /usr/local/bin

#创建目录结构
#创建日志目录
mkdir -p /seaweedfs/log/{master1,master2,master3,volume1,volume2,volume3,filer1,filer2,mount1,mount2}

# 创建数据存储目录
mkdir -p /seaweedfs/{master/{mdir1,mdir2,mdir3},volume/{data1,data2,data3},mount1,mount2}

# 生成配置文件
mkdir -p /seaweedfs/filer
/usr/local/bin/weed scaffold -config filer -output="/seaweedfs/filer/"

#查看目录结构
tree /seaweedfs

#生成服务启动文件
function create_service(){
cat <<EOF > /lib/systemd/system/${service_name}.service
[Unit]
Description=weed-master-server
After=network.target

[Service]
ExecStart=${command}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}


#master服务
service_name="weed-master-server1"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/master1 master -mdir=/seaweedfs/master/mdir1 -peers=${ip}:9331,${ip}:9332,${ip}:9333 -port=9331 -defaultReplication=001"
create_service

service_name="weed-master-server2"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/master2 master -mdir=/seaweedfs/master/mdir2 -peers=${ip}:9331,${ip}:9332,${ip}:9333 -port=9332 -defaultReplication=001"
create_service

service_name="weed-master-server3"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/master3 master -mdir=/seaweedfs/master/mdir3 -peers=${ip}:9331,${ip}:9332,${ip}:9333 -port=9333 -defaultReplication=001"
create_service

#volume服务
service_name="weed-volume-server1"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/volume1 volume -dir=/seaweedfs/volume/data1 -max=300  -mserver=${ip}:9331,${ip}:9332,${ip}:9333 -port=8081"
create_service

service_name="weed-volume-server2"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/volume2 volume -dir=/seaweedfs/volume/data2 -max=300  -mserver=${ip}:9331,${ip}:9332,${ip}:9333 -port=8082"
create_service

service_name="weed-volume-server3"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/volume3 volume -dir=/seaweedfs/volume/data3 -max=300  -mserver=${ip}:9331,${ip}:9332,${ip}:9333 -port=8083"
create_service

#filer服务
service_name="weed-filer-server1"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/filer1 filer -master=${ip}:9331,${ip}:9332,${ip}:9333 -port=8801 -defaultReplicaPlacement=001"
create_service

service_name="weed-filer-server2"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/filer2 filer -master=${ip}:9331,${ip}:9332,${ip}:9333 -port=8802 -defaultReplicaPlacement=001"
create_service

#mount服务
service_name="weed-mount-server1"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/mount1 mount -filer=${ip}:8801 -dir=/seaweedfs/mount1"
create_service

service_name="weed-mount-server2"
command="/usr/local/bin/weed -logdir=/seaweedfs/log/mount2 mount -filer=${ip}:8802 -dir=/seaweedfs/mount2"
create_service

# 重载配置
systemctl daemon-reload

## 启动所有服务
systemctl start weed-master-server1.service
systemctl start weed-master-server2.service
systemctl start weed-master-server3.service
systemctl start weed-volume-server1.service
systemctl start weed-volume-server2.service
systemctl start weed-volume-server3.service
systemctl start weed-filer-server1.service
systemctl start weed-filer-server2.service
systemctl start weed-mount-server1.service
systemctl start weed-mount-server2.service

#设置服务开机自启
systemctl enable weed-master-server1.service
systemctl enable weed-master-server2.service
systemctl enable weed-master-server3.service
systemctl enable weed-volume-server1.service
systemctl enable weed-volume-server2.service
systemctl enable weed-volume-server3.service
systemctl enable weed-filer-server1.service
systemctl enable weed-filer-server2.service
systemctl enable weed-mount-server1.service
systemctl enable weed-mount-server2.service

#查看服务状态
systemctl status weed-master-server1.service
systemctl status weed-master-server2.service
systemctl status weed-master-server3.service
systemctl status weed-volume-server1.service
systemctl status weed-volume-server2.service
systemctl status weed-volume-server3.service
systemctl status weed-filer-server1.service
systemctl status weed-filer-server2.service
systemctl status weed-mount-server1.service
systemctl status weed-mount-server2.service

- [seaweed仓库地址](https://github.com/chrislusf/seaweedfs)
- [seaweed版本发布地址](https://github.com/chrislusf/seaweedfs/releases)

原理图

![image.png](images/4.png)

master:9333

![image.png](images/1.png)

volume1:8080

![image.png](images/2.png)

volume2:8081

![image.png](images/3.png)

filer:8888

![image.png](images/5.png)


## 1.文件说明

### weed
seaweed二进制文件

### weed-master-server.service
master节点启动文件

## weed-volume-server1/2.service
volume服务启动文件

## weed-filer-server.service
filer服务启动文件

## weed-mount.service
挂载服务

## upload.sh
文件上传脚本

## 2.seaweed用法简介

### 2.1启动主服务器
```
> ./weed master
```

### 2.2启动卷服务器
```
> ./weed volume -dir="/tmp/data1" -max=5  -mserver="localhost:9333" -port=8080 &
> ./weed volume -dir="/tmp/data2" -max=10 -mserver="localhost:9333" -port=8081 &
```

### 2.3启动文件服务器
```
> ./weed filer -master="localhost:9333" -port=8888
```

## 3.上传文件
### 3.1未启动filer服务之前
要上传文件，请执行以下操作：首先，发送HTTP POST，PUT或GET请求/dir/assign以获取fid和卷服务器URL：
```
> curl http://localhost:9333/dir/assign
{"count":1,"fid":"3,01637037d6","url":"127.0.0.1:8080","publicUrl":"localhost:8080"}
```

其次，要存储文件内容，请url + '/' + fid从响应中发送HTTP多部分POST请求：
```
> curl -F file=@/home/chris/myphoto.jpg http://127.0.0.1:8080/3,01637037d6
{"name":"myphoto.jpg","size":43234,"eTag":"1cc0118e"}
```

### 3.2启动filer服务之后
```
# 上传文件，读取文件
curl -F file=@/root/test.txt http://localhost:8888/text/
curl "http://localhost:8888/text/test.txt"

# 以新的名称重命名上传后的文件
curl -F file=@/root/test.txt http://10.0.20.46:8888/text/new.txt
curl "http://localhost:8888/text/new.txt"

# 列表展示目录中的文件
visit "http://localhost:8888/path/to/sources/"

# 筛选目录中的文件
visit "http://localhost:8888/path/to/sources/?lastFileName=abc.txt&limit=50"

# 删除文件
curl -X DELETE "http://localhost:8888/text/new.txt"

# 递归删除路径下所有的文件以及目录
curl -X DELETE http://localhost:8888/path/to/dir?recursive=true
# 递归删除所有的文件以及目录，忽略递归错误
curl -X DELETE http://localhost:8888/path/to/dir?recursive=true&ignoreRecursiveError=true
```

## 4.部署seaweedfs步骤

### 4.1 克隆项目
```
git clone https://github.com/Leif160519/seaweedfs.git
```

### 4.2 将weed二进制程序复制到`/usr/local/bin`下
```
cd seaweedfs
cp weed /usr/local/bin
```

### 4.3 新建存储目录
```
# 新建块存储目录
mkdir -p /seaweedfs/block/{1,2}
# 新建挂载存储目录
mkdir -p /seaweedfs/mount
```

### 4.4 将服务启动配置文件放到指定目录下
```
# ubuntu和centos都适用
cp weed-*.service /lib/systemd/system
```

### 4.5 启动相关服务
```
systemctl start weed-master-server.service
systemctl start weed-volume-server1.service 
systemctl start weed-volume-server2.service 
systemctl start weed-filer-server.service 
systemctl start weed-mount-server.service
```

### 4.6 设置开机启动
```
systemctl enable weed-master-server.service
systemctl enable weed-volume-server1.service
systemctl enable weed-volume-server2.service
systemctl enable weed-filer-server.service
systemctl enable weed-mount-server.service
```

## 5.参考
- [seaweedfs搭建与使用](https://blog.wangqi.love/articles/seaweedfs/seaweedfs%E6%90%AD%E5%BB%BA%E4%B8%8E%E4%BD%BF%E7%94%A8.html)


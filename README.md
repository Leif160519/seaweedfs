- [seaweed仓库地址](https://github.com/chrislusf/seaweedfs)
- [seaweed版本发布地址](https://github.com/chrislusf/seaweedfs/releases)

seaweedfs版本：1.87 [a6b59d5](https://github.com/chrislusf/seaweedfs/commit/a6b59d50f7f36a36f42ace7a9fa94b60805b78be)

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

### /bin/weed
seaweed二进制文件

### single.sh
单节点自动化搭建脚本

文件结构:
```
/seaweedfs
├── filer
├── log
│   ├── filer
│   ├── master
│   ├── mount
│   └── volume
├── master
├── mount
└── volume
```

### cluster.sh
集群自动化搭建脚本

文件结构：
```
/seaweedfs/
├── filer
├── log
│   ├── filer
│   ├── master1
│   ├── master2
│   ├── master3
│   ├── mount
│   ├── volume1
│   ├── volume2
│   └── volume3
├── master
│   ├── mdir1
│   ├── mdir2
│   └── mdir3
├── mount
└── volume
    ├── data1
    ├── data2
    └── data3
```

> master节点必须奇数个
> 当filer与mount一起使用时，filer仅提供文件元数据检索，实际文件内容直接在mount和volume服务器之间读写，所以不需要多个filer 


### upload.sh
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
参看`single.sh`和`cluster.sh`脚本注解

## 5.关于数据副本Replication
| xyz |	Meaning |
| --- | ------- |
| 000 | 不复制，只有一个副本，默认设置 |
| 001 |	在相同的机架上复制一份 |
| 010 |	在相同数据中心的不同的机架上复制一份 |
| 100 |	在另一个数据中心上复制一份 |
| 200 |	在其他两个不同的数据中心上复制两份 |
| 110 |	在不同的机架上复制一份，并在不同的数据中心上复制一份 |

| 列 | 含义 |
| - | ----- |
| x | number of replica in other data centers |
| y | number of replica in other racks in the same data center |
| z | number of replica in other servers in the same rack |

> 创建的物理副本数量等于X+Y+Z+1，XYZ数字取值范围为0,1,2。

### 5.1 如何使用
在master上指定复制类型并启动之后，启动volume server的参数上指定`datacenter`和`rack`：
```
-dataCenter=dc1 -rack=rack1 
```

[详见wiki](https://github.com/chrislusf/seaweedfs/wiki/Replication)

## 6.关于多个filer和多个mount
[issuse 1423](https://github.com/chrislusf/seaweedfs/issues/1423)

## 7.关于filer高可用和负载均衡
可以使用keepalived的方式实现filer的负载均衡，保证每个局域网只有一个filer在工作，从而避免多个mount客户端数据不同步的问题。

## 8.关于元数据的存储的比较
详情：[SeaweedFS Wiki-Filer Stores](https://www.bookstack.cn/read/seaweedfs-wiki/3550db3b29308feb.md)

| 文件存储名称 | 查找复杂度 | 文件夹中文件数目 |          可扩展性         | Renaming | TTL |                                注意                               |
| ------------ | ---------- | ---------------- | ------------------------- | -------- | --- | ----------------------------------------------------------------- |
|     内存     |     O(1)   |    受内存限制    |         本地，快速        |          |     |                    仅用于测试，没有持久性存储                     |
|    leveldb   |   O(logN)  |      无限制      |         本地，非常快      |          |     |                             默认，可扩展                          |
|   leveldb2   |   O(logN)  |      无限制      | 本地，非常快，比leveldb快 |          |     | 与leveldb相似，查找键的一部分是128位MD5，而不是较长的完整文件路径 |
|     Redis    |   O(logN)  |      无限制      |     本地或分布式，最快    |          |  是 |               一个目录的子文件名存储在一个键值输入中              |
|   Cassandra  |   O(logN)  |      无限制      |    本地或分布式，非常快   |          |  是 |                                                                   |
|     MySql    |   O(logN)  |      无限制      |     本地或分布式，快速    | 原子操作 |     |                               易于管理                            |
|   Postgres   |   O(logN)  |      无限制      |     本地或分布式，快速    | 原子操作 |     |                               易于管理                            |
|     MemSql   |   O(logN)  |      无限制      |         分布式，快速      | 原子操作 |     |                                可扩展                             |
|      TiDB    |   O(logN)  |      无限制      |         分布式，快速      | 原子操作 |     |                                可扩展                             |
| CockroachDB  |   O(logN)  |      无限制      |         分布式，快速      | 原子操作 |     |                                可扩展                             |
|     Etcd     |   O(logN)  |     10GB左右     |   分布式，每秒10000次写入 |          |     |                            没有SPOF。高可用                       |
|     TiKV     |   O(logN)  |      无限制      |     本地或分布式，快速    |          |     |                                易于管理                           |

切换数据存储
```
# first save current filer meta data
 
$ weed shell
> fs.cd   http://filerHost:filerPort/
> fs.meta.save
...
total 65 directories, 292 files
meta data for http://localhost:8888/ is saved to localhost-8888-20190417-005421.meta
> exit
 
# now switch to a new filer, and load the previously saved metadata
$ weed shell
> fs.meta.load localhost-8888-20190417-005421.meta
...
total 65 directories, 292 files
localhost-8888-20190417-005421.meta is loaded to http://localhost:8888/
```

## 9.关于性能指标
参考：[System Metrics](https://github.com/chrislusf/seaweedfs/wiki/System-Metrics)

在所有的master节点命令后面添加`-metrics.address=<prometheus_gateway_host_name>:<prometheus_gateway_port>`参数即可

> 需要额外安装prometheus pushgateway
## 10.参考
- [seaweedfs搭建与使用](https://blog.wangqi.love/articles/seaweedfs/seaweedfs%E6%90%AD%E5%BB%BA%E4%B8%8E%E4%BD%BF%E7%94%A8.html)
- [海草海草随波飘摇，海草海草浪花里舞蹈](https://github.com/bingoohuang/blog/issues/57)

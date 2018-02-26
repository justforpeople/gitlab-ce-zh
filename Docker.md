# Docker的安装

## 背景说明

一台阿里云ECS，有系统盘，有数据盘。

要求：

1. 安装docker服务。
2. docker服务的数据存放在数据盘上。

## 一、挂载数据盘

阿里云云盘挂载ECS操作请参考[网址](https://help.aliyun.com/document_detail/25446.html?spm=a2c4g.11174283.6.661.eXNuUF)。

## 二、数据盘分区及格式化

### a、查看磁盘

执行如下命令：

```bash
fdisk -l
```

命令执行后显示信息如下：

```bash
Disk /dev/vda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0008d73a

   Device Boot      Start         End      Blocks   Id  System
/dev/vda1   *        2048    83884031    41940992   83  Linux

Disk /dev/vdb: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

注：
1. 默认的数据盘显示为dev/vd?，其中 ? 是 a−z 的任一个字母。
2. 本例中挂载了一个/dev/vdb的磁盘，40G容量，且未分区。

### b、执行分区操作

执行如下命令：

```bash
fdisk /dev/vdb #fdisk命令后需输入磁盘名
```

命令执行后显示信息如下：

```bash
Welcome to fdisk (util-linux 2.23.2).

Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table
Building a new DOS disklabel with disk identifier 0x56b3abc9.

Command (m for help): n #此处键入n表示创建新的磁盘分区
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p): #此处直接回车表示使用默认值p，创建主分区
Using default response p
Partition number (1-4, default 1): #此处直接回车表示使用默认值1，表示创建主分区1个
First sector (2048-83886079, default 2048): #此处直接回车表示使用默认值2048，表示新创建主分区起始扇区2048
Using default value 2048
Last sector, +sectors or +size{K,M,G} (2048-83886079, default 83886079): #此处直接回车表示使用默认值83886079，表示新创建主分区结束扇区83886079
Using default value 83886079
Partition 1 of type Linux and of size 40 GiB is set

Command (m for help): wq #此处输入wq，表示保存分区设定并退出分区命令
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```

### c、执行格式化操作

执行如下命令：

```bash
mkfs.ext3 /dev/vdb1 #mkfs.ext3命令后需输入磁盘分区名
```

命令执行后显示信息如下：

```bash
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
2621440 inodes, 10485504 blocks
524275 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=4294967296
320 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
	4096000, 7962624

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done   
```

## 三、数据盘挂载操作

### a、手动挂载数据盘

执行如下命令：

```bash
mkdir /data #创建目录/data用于挂载数据盘
mount /dev/vdb1 /data #将磁盘分区/dev/vdb1挂载在/data目录下
```

### b、启动时挂载数据盘

执行如下命令：

```bash
echo /dev/vdb1 /data ext3 defaults 1 1 >> /etc/fstab #将挂载命令增加到启动配置文件中
```

## 四、安装docker应用

### a、将操作系统升级，同时更新最新的包发布源。

执行如下命令：

```bash
yum -y update #升级系统应用
yum -y install epel-release #更新yum安装源信息
```

### b、查看最新的docker引擎安装包：

[具体网址](https://yum.dockerproject.org/repo/main/centos/7/Packages/)

### c、下载并安装docker引擎。

执行如下命令：

```bash
mkdir -p /data/setup/ #在数据盘目录/data下创建安装包目录setup
cd /data/setup/ #进入安装包目录setup
wget https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-1.13.1-1.el7.centos.x86_64.rpm #下载安装docker安装rpm包
yum -y install docker-engine-1.13.1-1.el7.centos.x86_64.rpm #yum安装docker引擎
```

### d、启动docker引擎，并设置为开机启动

执行如下命令：

```bash
systemctl start docker #启动docker服务
systemctl enable docker #设置docker服务为服务器重启后自动启动
```

### e、将docker相关数据文件移动到数据盘

执行如下命令：

```bash
systemctl stop docker #停止docker服务
mv /var/lib/docker /data/ #将docker数据目录移动到/data目录下
ln -s /data/docker /var/lib/docker #制作软连接映射，将数据盘下的docker目录映射为原docker目录
```

### f、配置镜像加速器

执行如下命令：

```bash
mkdir -p /etc/docker #创建目录/etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://yekyiho7.mirror.aliyuncs.com"]
}
EOF #在/etc/docker目录中创建文件daemon.json，并设定仓库镜像参数。
systemctl daemon-reload #加载上述参数
```

### g、重新启动docker，并查看docker版本

执行如下命令：

```bash
systemctl start docker #启动docker服务
docker --version #查看docker服务版本
```

显示版本信息如下：

```bash
Docker version 1.13.1, build 092cba3
```

## 总结

完成上述操作，即完成了docker相关的安装操作。

# Nginx镜像的使用

## 背景说明

一台阿里云ECS，有系统盘，有数据盘。

已安装了docker服务。

有关docker的安装可参考[Docker安装](Docker.md)。

要求：

获取并使用Nginx镜像。

## 一、获取Nginx镜像

执行如下命令：

```bash
docker pull nginx #获取Nginx镜像
```

## 二、构建自定义网络

执行如下命令：

```bash
docker network create --driver bridge --subnet=10.0.0.0/8 --gateway 10.0.0.1 main_net
```

构建10.0.0.0/8网段为自定义网络，该网络的可使用IP地址最多。

初步的网站规划：

1. 10.0.0.1作为网段网关，分配给宿主机。
2. 10.0.0.2作为http协议的nginx反向代理，映射宿主机的80，部署网站引用。
3. 10.0.0.3作为https协议的nginx反向代理，映射宿主机的443端口，部署网站引用。
4. 其他IP可按需分配用途。

注：

ECS私有网络的IP最好不要和docker自定义网络有重合，以便出现路由异常。

后续创建的所有容器都使用上面创建的自定义网络内部的IP，以便容器之间互联。

## 三、启动nginx容器

执行如下命令：

```bash
mkdir -p /data/main/ #创建主配置目录
docker run \
-dit \
--rm \
--name main_nginx \
nginx #首次启动nginx镜像
docker cp main_nginx:/etc/nginx /data/main/ #将启动后nginx容器中的配置目录复制到宿主机，以便永久保存相关配置
docker stop main_nginx #停止main_nginx容器运行。注：停止后该容器会自动删除
cd /data/main/ #进入主配置目录
cp -rf nginx https #将基础配置复制一份作为https配置
docker run \
-dit \
--rm \
--name nginx_normal \
--network main_net \
--ip 10.0.0.2 \
-v /data/main/nginx:/etc/nginx:ro \
-p 80:80 \
nginx #创建nginx_normal容器，映射宿主机80端口，并使用数据卷/data/main/nginx中的配置
docker run \
-dit \
--rm \
--name nginx_ssl \
--network main_net \
--ip 10.0.0.3 \
-v /data/main/https:/etc/nginx:ro \
-p 443:443 \
nginx #创建nginx_ssl容器，映射宿主机443端口，并使用数据卷/data/main/https中的配置
```

注：

将nginx配置文件转移到宿主机中是为了便于永久保存配置信息，以及后续修改配置。

将80端口和443端口分成两个容器处理，是为了使开启了ssl服务的nginx容器和未开启ssl服务的nginx容器避免互相干扰。

因为有时候需要在这台服务器上同时放http协议和https协议的网站，如果只使用一个nginx容器会造成异常。

后续修改了相关配置文件后，执行以下命令即可生效：

```bash
docker exec -it nginx_normal nginx -s reload #在main_nginx容器中重新加载配置文件
docker exec -it nginx_https nginx -s reload #在main_nginx容器中重新加载配置文件
```

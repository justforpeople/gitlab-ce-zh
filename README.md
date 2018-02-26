# GitLab汉化包使用方式

## 背景说明

一台阿里云ECS，有系统盘，有数据盘。

已安装了docker服务，并使用了Nginx镜像。

有关docker的安装可参考[Docker安装](Docker.md)。
有关Nginx镜像的使用可参考[Nginx镜像使用](Nginx.md)。

要求：

使用gitlab官方提供的社区版10.5.1版本镜像，并进行汉化。

## 一、获取gitlab-ce官方镜像

```bash
docker pull gitlab/gitlab-ce
```

注：

当前汉化版本为10.5.1版本，如果后续官方镜像版本升级，可能会造成该汉化包无法使用。

可考虑下载我在阿里云镜像仓库备份的镜像文件，获取方式如下。获取后注意将镜像重命名。

```bash
#公网地址:
docker pull registry.cn-beijing.aliyuncs.com/marbleqi/gitlab:10.5.1
docker tag registry.cn-beijing.aliyuncs.com/marbleqi/gitlab:10.5.1 gitlab/gitlab-ce
#经典内网:
docker pull registry-internal.cn-beijing.aliyuncs.com/marbleqi/gitlab:10.5.1
docker tag registry-internal.cn-beijing.aliyuncs.com/marbleqi/gitlab:10.5.1 gitlab/gitlab-ce
#VPC网络:
docker pull registry-vpc.cn-beijing.aliyuncs.com/marbleqi/gitlab:10.5.1
docker tag registry-vpc.cn-beijing.aliyuncs.com/marbleqi/gitlab:10.5.1 gitlab/gitlab-ce
```

## 二、启动gitlab镜像

```bash
docker run \
-dit \
--rm \
--name tool_gitlab \
--network main_net \
--ip 10.115.0.30 \
-v /data/tool/gitlab/etc:/etc/gitlab \
-v /data/tool/gitlab/data:/var/opt/gitlab \
-v /data/tool/gitlab/log:/var/log/gitlab \
-p 2203:22 \
gitlab/gitlab-ce
```

注：

映射的三个数据卷请注意永久保存，其中内容分别是配置文件，数据文件（包括数据库和版本库），日志文件。


## 三、在主nginx配置文件中增加反向代理配置
在/data/main/nginx/conf.d/下增加文件tool_gitlab.conf

文件内容：
```bash
#以下配置为将域名gitlab.yourdomain.com反向代理到宝塔面板的管理页面
#注：在域名解析设置中需把域名gitlab.yourdomain.com指向该阿里云ECS的公网IP
server{
        listen       80;
        server_name gitlab.yourdomain.com;
        location / {
                proxy_redirect off;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_pass http://10.115.0.30/;
                break;
        }
}
```

执行nginx容器反向代理加载最新配置命令
```bash
docker exec -it main_nginx nginx -s reload #在main_nginx容器中重新加载配置文件（在宿主机中执行该命令）
```

## 四、汉化gitlab
```bash
cd /data/setup/ #进入文件安装目录（宿主机内执行）
yum -y install git #安装git客户端（宿主机内执行）
#--------首次下载汉化包时，执行以下命令---------------
git clone https://github.com/marbleqi/gitlab-ce-zh.git #下载汉化包版本库（宿主机内执行）
#--------后续更新汉化包时，执行以下命令
cd gitlab-ce-zh #进入版本目录
git pull origin #从远端获取最新库
git branch -a #显示最新的分支清单
git checkout remotes/origin/v10.5.1-zh-patch #切换到相应版本的汉化分支目录
cd .. #返回上一级目录
#--------------------------------------------------
docker cp gitlab-ce-zh tool_gitlab:/opt/gitlab/embedded/service/ #将汉化文件从宿主机复制到容器中（宿主机内执行）
docker exec -it tool_gitlab bash #进入容器（宿主机内执行）
cd /opt/gitlab/embedded/service/ #进入网页文件相关目录（容器内执行）
cp -rf gitlab-ce-zh/* gitlab-rails/ #将汉化文件覆盖原文件（容器内执行）

vi /etc/gitlab/gitlab.rb #编辑gitlab配置文件（容器内执行）
#--------------------------
#第一处修改前原文
# external_url 'GENERATED_EXTERNAL_URL'
#第一处修改后内容
external_url 'http://gitlab.yourdomain.com/' #修改为域名
#第二处修改前原文
# gitlab_rails['time_zone'] = 'UTC'
#第二处修改后内容
gitlab_rails['time_zone'] = 'PRC' #将标准时修改为中国时间
#第三处修改前原文
# gitlab_rails['gitlab_shell_ssh_port'] = 22
#第三处修改后内容
gitlab_rails['gitlab_shell_ssh_port'] = 2203 #修改ssh端口
#--------------------------

gitlab-ctl reconfigure #使修改的配置文件生效（容器内执行）
#注：如果上述命令执行后，未汉化或有异常，则执行以下命令
gitlab-ctl stop #停止gitlab服务（容器内执行）
gitlab-ctl start #启动gitlab服务（容器内执行）
```
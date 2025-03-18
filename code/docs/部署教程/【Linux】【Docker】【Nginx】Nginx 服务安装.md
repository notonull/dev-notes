---
title: 【Linux】【Docker】【Nginx】Nginx服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - nginx
createTime: 2025/03/18 09:00:00
permalink: /blog/l8j0catv/
---

## 1.新建宿主机挂载目录

```bash
mkdir -p /opt/app/nginx/{conf}{logs}{html}
```
## 2.查询docker hub镜像
```bash
sudo docker search nginx
```
## 4.拉取镜像
```bash
sudo docker pull nginx
```
## 5.查看本地镜像
```bash
sudo docker images
```
## 6.运行镜像
```bash
sudo docker run -d \
  --name nginx \
  -p 80:80 \
  -p 443:443 \
  -v /opt/app/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
  -v /opt/app/nginx/conf/conf.d:/etc/nginx/conf.d \
  -v /opt/app/nginx/logs:/var/log/nginx \
  -v /opt/app/nginx/html:/usr/share/nginx/html \
  --restart always \
  nginx:latest
```

| 指令      | 描述     |
| --------- | -------- |
| -p        | 映射端口 |
| --name    | 容器名称 |
| -v        | 卷挂载   |
| -d        | 后台运行 |
| --restart | 重启策略 |

## 常用命令

```bash
docker ps
docker images
docker logs #id
docker rm #id
docker stop #name
docker start #name
```

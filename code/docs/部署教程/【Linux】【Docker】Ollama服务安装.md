---
title: 【Linux】【Docker】Ollama服务安装
toc: true
tags:
  - linux
  - docker
  - ollma
createTime: 2025/03/18 09:00:00
permalink: /blog/4f5zpe3s/
---

#### 【Linux】【Docker】Ollama服务安装

**参考**：https://hub.docker.com/r/ollama/ollama

##### 2.安装NVIDIA 容器工具包

https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installation

###### 2.1.Linux Ubuntu 

[【Linux】【Ubuntu】【NVIDIA】NVIDIA 容器工具包安装](./【Linux】【Ubuntu】【NVIDIA】NVIDIA 容器工具包安装.md)

##### 2.配置 Docker 以使用 Nvidia 驱动程序

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

##### 2.新建宿主机挂载目录

```bash
sudo mkdir ollama
```

##### 2.查询docker hub镜像

```bash
sudo docker search ollama
```

##### 4.拉取镜像

```bash
docker pull ollama/ollama
```

##### 5.查看本地镜像

```bash
sudo docker images
```

##### 6.运行镜像

```bash
sudo docker run -d \
  --gpus=all \
  --name ollama \
  -v /opt/app/ollama:/root/.ollama \
  -p 11434:11434 \
  ollama/ollama
  
docker run -d -p 11434:11434 --gpus=all -v /opt/app/ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ollama/ollama

```

| 指令      | 描述                      |
| --------- | ------------------------- |
| -p        | 映射端口                  |
| --gpus    | 分配所有可用的 GPU 给容器 |
| --name    | 容器名称                  |
| -v        | 卷挂载                    |
| -d        | 后台运行                  |
| --restart | 重启策略(当前未设置)      |

##### 常用命令

```bash
docker ps
docker images
docker logs #id
docker rm #id
docker stop #name
docker start #name
```
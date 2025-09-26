---
title: 【Linux】【Docker】【Ollama】Ollama服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - docker
  - Ollama
createTime: 2025/03/18 09:00:00
updateTime: 2025/04/12 19:11:00
permalink: /blog/4f5zpe3s/
---
## 1.镜像获取

### 1.1.查询docker hub镜像

```bash
sudo docker search ollama
```

### 1.2.拉取镜像

```bash
docker pull ollama/ollama
```

### 1.3.查看本地镜像

```bash
sudo docker images
```

## 2.环境准备

### 2.1.新建宿主机挂载目录

```bash
sudo mkdir -p /opt/server/ollama
```

### 2.2.安装NVIDIA 容器工具包

[【Linux】【Ubuntu】【NVIDIA】NVIDIA 容器工具包安装](./【Linux】【Ubuntu】【NVIDIA】NVIDIA 容器工具包安装.md)

### 2.3.配置 Docker 以使用 Nvidia 驱动程序

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## 3.启动镜像

#### 3.1.1.docker run 运行

```shell
sudo docker run -d \
  --gpus=all \
  --name ollama \
  -v /opt/server/ollama/data:/root/.ollama \
  -p 11434:11434 \
  --restart unless-stopped \
  ollama/ollama
```

#### 3.1.2.docker compose 运行

```bash
## 切换目录
cd /opt/server/ollama
## 设置docker compose yml
vim docker-compose.yml
## 后台启动
docker compose up -d
## 关闭销毁
docker compose down
```

**docker-compose.yml**

```yaml
version: "3.9"

services:
  ollama:
    image: ollama/ollama
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - /opt/server/ollama/data:/root/.ollama
    deploy:
      restart_policy:
        condition: any
    # GPU 支持，完全对应 --gpus=all
    runtime: nvidia
```

### 3.2.参数解释

| 指令        | 描述                      |
| ----------- | ------------------------- |
| `-p`        | 映射端口                  |
| `--gpus`    | 分配所有可用的 GPU 给容器 |
| `--name`    | 容器名称                  |
| `-v`        | 卷挂载                    |
| `-d`        | 后台运行                  |
| `--restart` | 重启策略                  |

| 参数                                       | 说明                                     |
| ------------------------------------------ | ---------------------------------------- |
| `-d`                                       | 后台运行容器                             |
| `--gpus=all`                               | 分配所有 GPU 给容器（用于模型推理加速）  |
| `--name ollama`                            | 容器命名为 ollama                        |
| `-v /opt/server/ollama/data:/root/.ollama` | 映射模型和配置文件目录（持久化模型数据） |
| `-p 11434:11434`                           | 映射端口 11434（Ollama 默认服务端口）    |
| `--restart unless-stopped`                 | 容器意外停止或系统重启时自动启动         |
| `ollama/ollama`                            | 使用 ollama 官方镜像                     |

## 常用命令

```markdown
# docker命令
## 查看所有容器
docker ps -a
## 查看所有镜像
docker images
## 查看容器日志
docker logs [容器ID或容器名]
## 删除容器
docker rm [容器ID或容器名]
## 删除镜像
docker rmi [镜像ID]
## 停止容器
docker stop [容器ID或容器名]
## 启动容器
docker start [容器ID或容器名]

# docker compose命令
## cd到docker-compose.yml所在目录
## 启动服务（后台模式）
docker compose up -d
## 启动服务（前台模式，日志直接输出）
docker compose up
## 停止服务
docker compose down
## 仅停止服务，不删除网络或卷
docker compose stop
## 启动已停止的服务
docker compose start
## 重启服务
docker compose restart
```
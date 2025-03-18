---
title: 【Linux】【Ubuntu】NVIDIA 容器工具包安装
copyright: CC-BY-4.0
tags:
  - linux
  - ubunto
  - nvidia
createTime: 2025/03/18 09:00:00
permalink: /blog/1fj6c2ck/
---

#### 【Linux】【Ubuntu】NVIDIA 容器工具包安装

**参考**：https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installation

##### 1.更新软件源

```bash
sudo apt update
sudo apt upgrade
```

##### 2.查询驱动

**输入指令**

```bash
nvidia-smi
```

**输出验证：已安装**

```bash
NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running.
```

**输出验证：未安装**

```bash
## 第一种情况
-bash: /usr/bin/nvidia-smi: No such file or directory
## 第二种情况
Command 'nvidia-smi' not found, but can be installed with:
sudo apt install nvidia-utils-470         # version 470.256.02-0ubuntu0.24.04.1, or
sudo apt install nvidia-utils-470-server  # version 470.256.02-0ubuntu0.24.04.1
sudo apt install nvidia-utils-535         # version 535.183.01-0ubuntu0.24.04.1
sudo apt install nvidia-utils-535-server  # version 535.216.01-0ubuntu0.24.04.1
sudo apt install nvidia-utils-550         # version 550.120-0ubuntu0.24.04.1
sudo apt install nvidia-utils-525         # version 525.147.05-0ubuntu1
sudo apt install nvidia-utils-525-server  # version 525.147.05-0ubuntu1
sudo apt install nvidia-utils-550-server  # version 550.127.05-0ubuntu0.24.04.1
```

##### 3.安装GPU驱动（验证输出：未安装）

```bash
## 选一个适合的，本次选择 服务器版本驱动包：主要针对服务器优化，但它同样适用于低端硬件，只是没有桌面驱动中的那些渲染功能。只要你的应用场景主要关注计算性能而非图形加速
sudo apt install nvidia-utils-535-server
```

##### 4.添加存储库

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

##### 5.再次更新软件源

```bash
sudo apt-get update
```

##### 6.安装NVIDIA 容器工具包

```bash
sudo apt-get install -y nvidia-container-toolkit
```

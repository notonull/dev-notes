---
title: Linux 离线包服务安装模板
copyright: CC-BY-4.0
tags:
  - linux
  - 模板
createTime: 2025/04/13 16:32:23
permalink: /blog/rp10nc8j/
---

## 1.参考

[官方地址](http://test.com)

[官方下载地址](http://test.com/en/download.html)

[官方文档](http://test.com/)

## 2.环境准备

### 2.1.离线源配置（可选）

#### 2.1.1.挂载镜像

```bash
mount /path/to/CentOS.iso /mnt/iso
```

#### 2.1.2.根据系统：配置源（dep）

```markdown
## 配置deb源
deb [trusted=yes] file:/mnt/iso focal main restricted
## 重新初始化源
apt update
```

#### 2.1.3.根据系统：配置源（rpm）

```bash
## 配置yum源
vim /etc/yum.repos.d/CentOS-Media.repo：
## 输入保存
[c7-media]
name=CentOS-Media
baseurl=file:///mnt/iso
enabled=1
gpgcheck=0
## 重新初始化源
yum clean all && yum makecache
```

#### 2.1.4.安装见2.3、2.4

### 2.2.上传安装

```markdown
# 安装方式（不推荐建议2.1.2方式）
## 查看系统架构
uname -m
## 根据架构从互联网下载对应deb 或 rpm
https://www.rpmfind.net/linux/rpm2html/search.php?query=
## 基于deb的批量安装
sudo dpkg -i *.deb
## 基于rpm的批量安装
sudo rpm -ivh *.rpm
```

### 2.3.yum安装

```bash
## 安装全部
```

| 依赖包                  | 作用               |
| ----------------------- | ------------------ |
|  |  |

### 2.4.apt安装

```bash
## 更新源
sudo apt update
## 安装全部
```

| 包名              | 作用说明                                                     |
| ----------------- | ------------------------------------------------------------ |
|  |  |

## 3.安装服务

### 3.1.上传

```bash
#可选步骤*根据情况选择上传方式
## n*.tar.gz 举例
## 选择位置
cd /opt/src
## 上传
rz
## 解压
tar -zxvf *.tar.gz
```

### 3.2.编译

```bash
## 可选编译
```

| 参数  | 说明     |
| ----- | -------- |
| 参数1 | 参数解释 |

### 3.3.安装

```bash
## 安装命令
```

## 4.后续配置

### 4.1.其他操作

```bash
## 其他操作
```

## 常用命令

```bash
## 命令列表
```


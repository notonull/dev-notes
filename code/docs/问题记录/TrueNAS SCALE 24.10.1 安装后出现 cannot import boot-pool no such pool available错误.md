---
title: TrueNAS SCALE 24.10.1 安装后出现 cannot import boot-pool no such pool available错误
copyright: CC-BY-4.0
tags:
  - truenas
createTime: 2025/04/13 01:30:19
permalink: /blog/zjf0rp91/
---

## 1.问题描述

### 1.1.问题背景

该问题出现在我尝试安装 TrueNAS SCALE 时，特别是在升级或安装过程中的某个阶段，系统未能成功导入 ***\*boot-pool\****。尽管安装过程中没有错误提示，但在启动时无法找到启动池，导致无法正常启动操作系统。

### 1.2.影响范围

无法正确安装truenas。

## 2.参考资料

### 2.1.TrueNAS论坛

[https://ixsystems.atlassian.net/browse/NAS-131890](https://ixsystems.atlassian.net/browse/NAS-131890)

### 2.2.Reddit TrueNAS 社区

[https://www.reddit.com/r/truenas/comments/1b13tf9/scale_clean_install_bootpool_not_found/](https://www.reddit.com/r/truenas/comments/1b13tf9/scale_clean_install_bootpool_not_found/)

## 3.场景还原

### 3.1.安装步骤

我按照官方文档进行安装，使用的是 **TrueNAS SCALE 24.10.1** 镜像。

### 3.2.硬件环境

SDD 安装过程中未选择任何额外的存储池，仅使用默认的启动池。

### 3.3.错误信息

启动时出现如下错误信息：cannot import 'boot-pool': no such pool available

## 4.排查过程

#### 4.1.重新安装

多次尝试重新安装，使用不同的磁盘进行测试，但问题仍然存在。

#### 4.2.检查ZFS池

使用 `zpool import` 命令检查可用池，但返回的结果没有显示任何有效的池。

#### 4.3.浏览社区

参考多个社区问题发现可能存在ZFS磁盘元数据残留问题导致

## 5.问题原因

- **ZFS 元数据** 残留导致的启动池问题，可能是安装过程中未完全清除磁盘上的旧数据或分区信息，导致系统无法找到正确的 **boot-pool**。
- 可能是非全新硬盘有历史元数据即便是重新分区格式依旧存在问题

## 4.解决过程

### 4.1.使用ISO启动盘启动

然后系统进入 **initramfs shell**

### 4.2.查看磁盘信息查找系统盘

即你用于安装 **TrueNAS** 的磁盘（比如 `/dev/sda` 或 `/dev/nvme0n1`），这是你要清除的磁盘。

```bash
lsblk
```

*注意：清除元数据会导致磁盘信息丢失，如有重要信切记备份后再执行操作。

### 4.3.清除磁盘元数据

使用 `wipefs` 清除磁盘上的所有文件系统标签：

```bash
# HDD 硬盘
wipefs --all /dev/sda

# SSD 硬盘
sudo blkdiscard /dev/sda

exit
```

### 4.4.重新安装或升级系统

重新安装或升级系统 问题会得到解决。

## 5.结论

其实解决方案并不理想，如链接所说，如果可以再升级或安装过程中弹出有效提示用户进行清除此问题就没那么难以解决。


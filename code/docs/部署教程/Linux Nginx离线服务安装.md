---
title: 【Linux】【Nginx】Nginx服务安装
copyright: CC-BY-4.0
tags:
  - linux
  - nginx
createTime: 2025/04/13 00:09:35
permalink: /blog/bja29csb/
---

## 1.参考

**官方地址:**
http://nginx.org

**官方下载地址:**
http://nginx.org/en/download.html

**官方文档**
http://nginx.org/en/docs/

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
yum -y install gcc gcc-c++ make libtool zlib zlib-devel openssl openssl-devel pcre pcre-devel
```

```bash
## 安装 gcc
yum install gcc-c++
 
## 安装 PCRE pcre-devel
yum install -y pcre pcre-devel
 
## 安装 zlib
yum install -y zlib zlib-devel
 
## 安装 Open SSL
yum install -y openssl openssl-devel
```

| 依赖包                  | 作用               |
| ----------------------- | ------------------ |
| `gcc/gcc-c++`           | C/C++ 编译器       |
| `make`                  | 构建工具           |
| `libtool`               | 支持自动构建共享库 |
| `pcre/pcre-devel`       | 正则表达式解析库   |
| `zlib/zlib-devel`       | 支持 Gzip 压缩     |
| `openssl/openssl-devel` | 支持 HTTPS 协议    |

### 2.4.apt安装

```bash
## 更新源
sudo apt update
## 安装全部
sudo apt install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
```

| 包名              | 作用说明                                                     |
| ----------------- | ------------------------------------------------------------ |
| `build-essential` | 安装常用编译工具（包括 `gcc`, `g++`, `make` 等），编译源码时必备。 |
| `libpcre3`        | 安装 PCRE 库（Perl Compatible Regular Expressions），支持正则匹配（用于 Nginx URL 解析）。 |
| `libpcre3-dev`    | 安装 PCRE 的开发头文件和静态库，编译时用到。                 |
| `zlib1g`          | 安装 zlib 压缩库，支持 gzip 压缩传输。                       |
| `zlib1g-dev`      | zlib 的开发文件，编译 Nginx 的 gzip 模块时需要。             |
| `libssl-dev`      | OpenSSL 的开发包，提供加密功能，编译带有 HTTPS（SSL）支持的 Nginx 时需要。 |

## 3.安装服务

### 3.1.上传nginx源码包

```bash
#可选步骤*根据情况选择上传方式
## nginx-*.tar.gz 举例
## 选择位置
cd /opt/src
## 上传
rz
## 解压
tar -zxvf nginx-*.tar.gz
```

### 3.2.编译

```bash
## cd 源码包
cd /opt/src/nginx-*
## 编译
./configure --prefix=/opt/app/nginx --with-http_stub_status_module --without-http-cache --with-http_ssl_module --with-http_gzip_static_module --with-ipv6
```

| 参数                             | 说明                                                       |
| -------------------------------- | ---------------------------------------------------------- |
| `--user=nginx`                   | 可选：指定运行 Nginx 的用户为 `nginx`                      |
| `--group=nginx`                  | 可选：指定运行 Nginx 的用户组为 `nginx`                    |
| `--prefix=/opt/app/nginx`        | 设置安装路径为 `/usr` 目录                                 |
| `--with-http_stub_status_module` | 启用 stub_status 模块，用于查看 Nginx 的状态（如连接数等） |
| `--without-http-cache`           | 禁用 HTTP 缓存功能                                         |
| `--with-http_ssl_module`         | 启用 HTTPS 支持                                            |
| `--with-http_gzip_static_module` | 启用对 `.gz` 静态文件的支持，提升性能                      |
| `--with-ipv6`                    | 启用对 IPv6 的支持                                         |

### 3.3.安装

```bash
make & make install
```

### 3.4.服务位置

```bash
cd /opt/app/nginx
```

## 4.后续配置

### 4.1.conf配置

[【Nginx】conf配置模板](../代码模板/Nginx%20conf配置模板.md)

## 常用命令

```bash
## 检查 nginx 配置
./nginx -t
## 启动 nginx
./nginx 
## 关闭 nginx
./nginx -s stop
## 重启 nginx
./nginx -s reload
```


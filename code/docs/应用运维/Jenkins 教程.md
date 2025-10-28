---
title: Jenkins 教程
copyright: CC-BY-4.0
tags:
  - jenkins
createTime: 2025/09/27 04:44:22
permalink: /blog/goyh85gw/
---

## 1.参考

[官方地址](https://www.jenkins.io/)

[中文社区地址](https://www.jenkins-zh.cn/)


## 2.前置条件

**系统版本:** any

**软件依赖:** any

**权限要求:** root

**网络要求:** any

**其他注意事项:** 

## 3.环境准备

### 3.1.linux

[docker安装](../部署教程/Linux Docker服务安装.md)

## 4.安装部署

### 4.1.linux

[docker安装jenkins服务](../部署教程/docker/Docker Jenkins服务安装.md)

## 5.配置说明

### 5.1.Plugin 插件

| 插件编码                    | 插件名称         |
| --------------------------- | ---------------- |
| Config File Provider Plugin | 配置文件程序插件 |
| Maven Integration plugin    | Maven 集成插件   |
| Publish Over SSH            | SSH发布插件      |

### 5.2.Config File Provider Plugin

**maven-setting**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" 
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
   <servers>
       <server>
           <id>maven-public</id>
           <username>dev-manager</username>
           <password>123456</password>
       </server>
       <server>
           <id>maven-releases</id>
           <username>dev-manager</username>
           <password>123456</password>
       </server>
       <server>
           <id>maven-snapshots</id>
           <username>dev-manager</username>
           <password>123456</password>
       </server>
   </servers>
   <mirrors>
       <mirror>
           <id>maven-public</id>
           <mirrorOf>*</mirrorOf>
           <url>http://192.168.1.12:8081/repository/maven-public/</url>
       </mirror>

        <mirror>
            <id>maven-default-http-blocker</id>
            <mirrorOf>external:http:*</mirrorOf>
            <name>Pseudo repository to mirror external repositories initially using HTTP.</name>
            <url>http://0.0.0.0/</url>
            <blocked>true</blocked>
        </mirror>
   </mirrors>
   <profiles>
       <profile>
           <id>local-snapshot</id>
           <repositories>
               <repository>
                   <id>local-snapshot</id>
                   <url>http://192.168.1.12:8081/repository/maven-public/</url>
                   <releases>
                       <enabled>true</enabled>
                       <updatePolicy>always</updatePolicy>
                   </releases>
                   <snapshots>
                       <enabled>true</enabled>
                       <updatePolicy>always</updatePolicy>
                   </snapshots>
               </repository>
           </repositories>
       </profile>
   </profiles>
   <activeProfiles>
       <activeProfile>local-snapshot</activeProfile>
   </activeProfiles>
</settings>
```



## 6.常用操作

### 6.1.安装配置 Config File Provider Plugin

**安装插件**

![image-20250927045657267](./../.vuepress/images/image-20250927045657267.png)

**新增配置**

![image-20250927045711559](./../.vuepress/images/image-20250927045711559.png)

![image-20250927045725833](./../.vuepress/images/image-20250927045725833.png)

![image-20250927045846397](./../.vuepress/images/image-20250927045846397.png)

![image-20250927045740452](./../.vuepress/images/image-20250927045740452.png)

**全局使用maven配置**

![image-20250927050153513](./../.vuepress/images/image-20250927050153513.png)

**局部使用maven配置**

![image-20250927050213021](./../.vuepress/images/image-20250927050213021.png)

![image-20250927050253276](./../.vuepress/images/image-20250927050253276.png)

![image-20250927050309930](./../.vuepress/images/image-20250927050309930.png)

### 6.2.安装配置 Maven

**全局配置**

![image-20250927050647390](./../.vuepress/images/image-20250927050647390.png)

**Maven安装**

![image-20250927050705609](./../.vuepress/images/image-20250927050705609.png)

**自动安装**

install automatically 在使用这maven时会自动下载

安装位置：`./tools/hudson.tasks.Maven_MavenInstallation`

![image-20250927050716359](./../.vuepress/images/image-20250927050716359.png)

### 6.3.安装配置 Publish Over SSH

**安装插件**

![image-20250927051247082](./../.vuepress/images/image-20250927051247082.png)

**配置SSH Servers**

![image-20250927051300948](./../.vuepress/images/image-20250927051300948.png)

![image-20250927051318526](./../.vuepress/images/image-20250927051318526.png)

**配置密码和发布目录**

![image-20250927051352318](./../.vuepress/images/image-20250927051352318.png)

**job配置发布**

![image-20250927051037235](./../.vuepress/images/image-20250927051037235.png)

`SourceFiles`工作区代发布文件

`Remove prefix`删除前缀

`Remote Directory`发布位置（默认时选定SSH的发布目录）

`Exec command`自定义执行命令

![image-20250927051629869](./../.vuepress/images/image-20250927051629869.png)

## 7.排错与日志

## 8.升级与维护

## 9.附录
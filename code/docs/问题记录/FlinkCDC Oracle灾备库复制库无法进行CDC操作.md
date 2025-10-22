---
title: FlinkCDC oracle-connector实时读取只读备库,无法创建相关权限表问题
copyright: CC-BY-4.0
tags:
  - flink
  - flinkCDC
  - oracle
---

## 1.问题描述

### 1.1.问题背景

该问题出现在oracle 灾备库为源端情况下，cdc 出现权限不足等一系列问题

### 1.2.影响范围

无法正常进行CDC操作

## 2.参考资料

### 2.1.Github Issues

[oracle-connector实时读取只读备库的问题](https://github.com/apache/flink-cdc/issues/1315)

### 2.2.Apache Issues

[支持从oracle备用数据库同步数据](https://issues.apache.org/jira/browse/FLINK-34774?filter=-4&jql=project%20%3D%20FLINK%20AND%20text%20~%20%22oracle%20standby%22%20order%20by%20created%20DESC)

### 2.2.Redhat Issues

[允许从只读 Oracle 备用灾难/恢复中读取](https://issues.redhat.com/browse/DBZ-3866)

[允许从 Oracle 只读物理 Oracle 读取](https://issues.redhat.com/browse/DBZ-6025)


## 3.场景还原

### 3.1.安装步骤

* flink 1.20.0
* flink-cdc 3.2.1
* flink-connector-oracle-cdc 3.2.1
* 已完成 Oracle Logmnr补全日志操作说明

### 3.2.硬件环境

-

### 3.3.错误信息

因为灾备库无法创建CDC用户给予相关权限，无法进行CDC操作；

若强行使用某一用户，启动时出现如下错误信息：`Database table 'LOG_MINING_FLUSH' no longer exists, supplemental log check skipped`，后续日志无获取元数据等过程

## 4.排查过程

#### 4.1.查看官方文档

未找到过于oracle灾备库相关处理流程，官方流程中需要cdc相关权限(即：用户本身创建新增编辑等权限主要是为了操作`LOG_MINING_FLUSH`) Logmnr等执行权限

#### 4.1.查看Issues

摘要：LogMiner 适配器依赖于两种与特定 Oracle LogMiner 选项直接相关的挖掘策略：

- `redo_log_catalog` => 来自重做日志的字典
- `在线目录`=> 在线目录字典

在这两种情况下，这些选项都需要对数据库具有可写访问权限，而这在使用 OADG (Oracle Active Data Guard) 的*物理备用配置中是无法实现的。这与下面*[zalmane](https://issues.redhat.com/secure/ViewProfile.jspa?name=zalmane)的输入一致，他指出 Oracle 不支持在使用物理备用数据库时使用 Oracle LogMiner。

## 5.问题原因

- Oracle 19以下版本基于logminer进行补全日志采集
- 基于logminer需要部分视图 存储过程执行权限
- flinkcdc 需要LOG_MINING_FLUSH记录抽取scn位置
- 已上在灾备库都无法对单一用户进行授权

## 4.解决过程

基于logminer操作的cdc流程无法在灾备库处理

## 5.结论

无法解决，必须在主库新建cdc用户授权执行


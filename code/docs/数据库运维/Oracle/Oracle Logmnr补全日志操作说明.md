---
title: Oracle Logmnr补全日志操作说明
copyright: CC-BY-4.0
tags:
  - oracle
  - binlog
createTime: 2025/09/17 10:52:52
permalink: /blog/hn7ynkvy/
---

## 1.参考

**官方地址:**
http://test.com

## 2.前置条件

**系统版本:** any

**软件依赖:** oracle

**权限要求:** any

**网络要求: **any

**其他注意事项:** any

## 3.环境准备

## 4.安装部署

[引用路径文档](./引用路径文档.md)

## 5.配置说明

### 5.1.开启BinLog模式

#### 5.1.1.查询数据库归档模式

**描述**：检查数据库是否启用归档模式。

**SQL**：

```sql
SELECT LOG_MODE FROM V$DATABASE;
```

**输出示例**：

| LOG\_MODE  |
| ---------- |
| ARCHIVELOG |

**开启归档日志模式**

```sql
sqlplus / as sysdba;
-- 先关闭数据库
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
```

#### 5.1.2.启用数据库级别补充日志

**描述**：开启数据库级别的补充日志，为 LogMiner 做准备。

**SQL**：

```sql
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
```

**输出示例**：成功执行，无返回结果

#### 5.1.3.启用表级全字段补充日志

**描述**：为特定表开启全列补充日志。

**SQL**：

```sql
ALTER TABLE "模式"."表名" ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
```

**输出示例**：成功执行，无返回结果

**参数说明**：

* `"模式"`：表所属 schema
* `"表名"`：需要补充日志的表

#### 5.1.4.查询表空间文件、归档文件、补全日志文件

```sql
## 归档日志文件记录
select * FROM v$archived_log;
## 补全日志文件记录
SELECT * FROM v$logfile;
## 表空间文件记录
SELECT * FROM dba_data_files;
```

### 5.2.创建CDC用户

```sql
-- ===========================================
-- 1️⃣ 创建 CDC/LogMiner 专用表空间
-- ===========================================
-- 注意：路径需提前在操作系统创建，Oracle 进程需有权限
CREATE TABLESPACE CDC_TBS
DATAFILE '/opt/oracle/oradata/SID/cdc_tbs.dbf'
SIZE 25M REUSE
AUTOEXTEND ON MAXSIZE UNLIMITED;

-- 可选：创建临时表空间用于排序和临时操作
CREATE TEMPORARY TABLESPACE CDC_TBS_TMP
TEMPFILE '/opt/oracle/oradata/SID/cdc_tbs_tmp.dbf'
SIZE 50M REUSE
AUTOEXTEND ON MAXSIZE 2G;

-- ===========================================
-- 2️⃣ 创建 CDC/LogMiner 专用用户
-- ===========================================
CREATE USER cdc_user IDENTIFIED BY 密码
  DEFAULT TABLESPACE CDC_TBS
  TEMPORARY TABLESPACE CDC_TBS_TMP
  QUOTA UNLIMITED ON CDC_TBS;

-- ===========================================
-- 1️⃣ 基础连接和会话控制
-- ===========================================

GRANT CREATE SESSION TO CDC_USER;   -- 允许登录数据库
GRANT SET CONTAINER TO CDC_USER;    -- 在 CDB/PDB 多租户环境中切换容器

-- ===========================================
-- 2️⃣ 元数据 / 数据字典访问
-- ===========================================

GRANT SELECT ON V_$DATABASE TO CDC_USER;      -- 查询数据库信息
GRANT SELECT ANY TABLE TO CDC_USER;           -- 查询任意用户的表
GRANT SELECT_CATALOG_ROLE TO CDC_USER;        -- 访问数据字典视图
GRANT EXECUTE_CATALOG_ROLE TO CDC_USER;       -- 执行数据字典里的 PL/SQL 包
GRANT SELECT ANY TRANSACTION TO CDC_USER;     -- 查询任意事务信息
GRANT ANALYZE ANY TO CDC_USER;                -- 分析任意对象（收集统计信息）

-- ===========================================
-- 3️⃣ LogMiner / 归档日志相关权限
-- ===========================================

GRANT LOGMINING TO CDC_USER;                        -- 使用 LogMiner
GRANT EXECUTE ON DBMS_LOGMNR TO CDC_USER;           -- 执行 LogMiner 包
GRANT EXECUTE ON DBMS_LOGMNR_D TO CDC_USER;         -- 执行 LogMiner 辅助包
GRANT SELECT ON V_$LOG TO CDC_USER;                 -- 读取联机日志视图
GRANT SELECT ON V_$LOG_HISTORY TO CDC_USER;         -- 读取日志历史
GRANT SELECT ON V_$LOGMNR_LOGS TO CDC_USER;         -- LogMiner 使用的日志列表
GRANT SELECT ON V_$LOGMNR_CONTENTS TO CDC_USER;     -- LogMiner 解出的日志内容
GRANT SELECT ON V_$LOGMNR_PARAMETERS TO CDC_USER;   -- LogMiner 参数
GRANT SELECT ON V_$LOGFILE TO CDC_USER;             -- 日志文件信息
GRANT SELECT ON V_$ARCHIVED_LOG TO CDC_USER;        -- 归档日志信息
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO CDC_USER; -- 归档目标状态

-- ===========================================
-- 4️⃣ DDL / DML 操作能力（可选，主要用于快照/DDL 同步）
-- ===========================================

GRANT CREATE TABLE TO CDC_USER;     -- 创建表
GRANT LOCK ANY TABLE TO CDC_USER;   -- 锁任意表
GRANT ALTER ANY TABLE TO CDC_USER;  -- 修改任意表
GRANT CREATE SEQUENCE TO CDC_USER;  -- 创建序列

```

### 5.3.测试Logmnr监控

#### 5.3.1. 查询 log 文件位置

**描述**：查看数据库 log 文件路径及状态，为 LogMiner 添加日志做准备。

**SQL**：

```sql
## 增量日志
SELECT * FROM V$LOGFILE;
## 归档日志
SELECT * FROM V$ARCHIVED_LOG
```

**输出示例**：

| GROUP# | MEMBER              | STATUS   |
| ------ | ------------------- | -------- |
| 1      | /oradata/redo01.log | ACTIVE   |
| 2      | /oradata/redo02.log | INACTIVE |

**参数说明**：无

#### 5.3.2.添加 log 文件到 LogMiner

**描述**：将 log 文件加入 LogMiner 会话。

**SQL**：

```sql
BEGIN
  DBMS_LOGMNR.ADD_LOGFILE(LOGFILENAME => '/home/oracle/app/oracle/oradata/helowin/redo01.log', OPTIONS => DBMS_LOGMNR.NEW);
  DBMS_LOGMNR.ADD_LOGFILE(LOGFILENAME => '/home/oracle/app/oracle/oradata/helowin/redo02.log', OPTIONS => DBMS_LOGMNR.ADDFILE);
  DBMS_LOGMNR.ADD_LOGFILE(LOGFILENAME => '/home/oracle/app/oracle/oradata/helowin/redo03.log', OPTIONS => DBMS_LOGMNR.ADDFILE);
END;
/
```

**输出示例**：成功执行，无返回结果

**参数说明**：

* `LOGFILENAME`：日志文件完整路径
* `OPTIONS`：

  * `DBMS_LOGMNR.NEW`：新建日志列表
  * `DBMS_LOGMNR.ADDFILE`：追加文件
  * `DBMS_LOGMNR.REMOVEFILE`：移除文件

#### 5.3.3.查询已添加监控日志文件

**描述**：查看当前 LogMiner 会话已添加的日志文件列表。

**SQL**：

```sql
SELECT * FROM V$LOGMNR_LOGS;
```

**输出示例**：

| LOGFILENAME         | STATUS |
| ------------------- | ------ |
| /oradata/redo01.log | ADDED  |
| /oradata/redo02.log | ADDED  |

**参数说明**：无

#### 5.3.4.启动 LogMiner

**描述**：启动日志监控，会话开始解析 redo 日志。

**SQL**：

```sql
BEGIN
  DBMS_LOGMNR.START_LOGMNR(
    OPTIONS => DBMS_LOGMNR.DICT_FROM_ONLINE_CATALOG + 
               DBMS_LOGMNR.COMMITTED_DATA_ONLY
  );
END;
/
```

**输出示例**：成功执行，无返回结果

**参数说明**：

* `DICT_FROM_ONLINE_CATALOG`：使用在线字典
* `COMMITTED_DATA_ONLY`：仅查询已提交数据

#### 5.3.5.查询 LogMiner 内容

**描述**：查看指定表的增量变更。

**SQL**：

```sql
SELECT SCN, TIMESTAMP, OPERATION, TABLE_NAME, SQL_REDO, SQL_UNDO 
FROM V$LOGMNR_CONTENTS 
-- WHERE TABLE_NAME = 'CG_DEPO_PE'
-- AND SCN BETWEEN 123450 AND 123460
ORDER BY TIMESTAMP DESC;
```

**输出示例**：

| SCN    | TIMESTAMP           | OPERATION | TABLE\_NAME  | SQL\_REDO                            | SQL\_UNDO                         |
| ------ | ------------------- | --------- | ------------ | ------------------------------------ | --------------------------------- |
| 123456 | 2025-08-29 11:10:00 | INSERT    | CG\_DEPO\_PE | INSERT INTO CG\_DEPO\_PE VALUES(...) | DELETE FROM CG\_DEPO\_PE WHERE... |

**参数说明**：

* `TABLE_NAME`：指定查询表名
* `SCN`：指定查询表名

#### 5.3.6. 停止 LogMiner

**描述**：停止 LogMiner 会话，释放资源。

**SQL**：

```sql
BEGIN
  DBMS_LOGMNR.END_LOGMNR;
END;
/
```

**输出示例**：成功执行，无返回结果

**参数说明**：无

## 6.常用操作

### 6.1.查询指令

```sql
-- 查询数据库归档模式
SELECT LOG_MODE FROM V$DATABASE;
-- 增量日志
SELECT * FROM V$LOGFILE;
-- 归档日志
SELECT * FROM V$ARCHIVED_LOG
```

### 6.2.设置指令

```sql
-- 启用数据库级别补充日志
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
-- 启用表级全字段补充日志
ALTER TABLE "模式"."表名" ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
```

### 6.3.Logmnr指令

```sql
-- 添加 log 文件到 LogMiner
/
BEGIN
  DBMS_LOGMNR.ADD_LOGFILE(LOGFILENAME => 'log path', OPTIONS => DBMS_LOGMNR.NEW);
END;
/
-- 查询已添加监控日志文件
SELECT * FROM V$LOGMNR_LOGS;

-- 启动 LogMiner
BEGIN
  DBMS_LOGMNR.START_LOGMNR(
    OPTIONS => DBMS_LOGMNR.DICT_FROM_ONLINE_CATALOG + 
               DBMS_LOGMNR.COMMITTED_DATA_ONLY
  );
END;
/

-- 查询 LogMiner 内容
SELECT SCN, TIMESTAMP, OPERATION, TABLE_NAME, SQL_REDO, SQL_UNDO 
FROM V$LOGMNR_CONTENTS 
ORDER BY TIMESTAMP DESC;

-- 停止 LogMiner
BEGIN
  DBMS_LOGMNR.END_LOGMNR;
END;
/
```

## 7.排错与日志

## 8.升级与维护

## 9.附录
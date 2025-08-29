---
title: 【Oracle】【BinLog】Oracle归档日志操作
copyright: CC-BY-4.0
tags:
  - oracle
  - binlog

---

## 1.简介

本文档介绍 Oracle 归档日志、增量日志及 LogMiner 的使用方法，包括数据库级别和表级补充日志设置、重做日志监控等。

## 2.前置准备

1. 数据库已开启归档模式（ARCHIVELOG）。
2. 用户具有 DBA 权限。
3. 确认 ORACLE\_HOME、ORACLE\_SID 配置正确。
4. 确认数据文件路径及日志文件路径。

---

## 3.场景化操作

### 3.1.查询归档日志信息

#### 3.1.1.视图说明

**视图**：V$DATABASE

**参数说明**：

| 字段                         | 描述/含义                                      |
| ---------------------------- | ---------------------------------------------- |
| DBID                         | 数据库唯一标识符                               |
| NAME                         | 数据库名称                                     |
| CREATED                      | 数据库创建时间                                 |
| RESETLOGS_CHANGE#            | 最近一次重置日志的 SCN                         |
| RESETLOGS_TIME               | 最近一次重置日志的时间                         |
| PRIOR_RESETLOGS_CHANGE#      | 上一次重置日志的 SCN                           |
| PRIOR_RESETLOGS_TIME         | 上一次重置日志时间                             |
| LOG_MODE                     | 日志模式（ARCHIVELOG / NOARCHIVELOG）          |
| CHECKPOINT_CHANGE#           | 数据库检查点 SCN                               |
| ARCHIVE_CHANGE#              | 归档日志 SCN                                   |
| CONTROLFILE_TYPE             | 控制文件类型                                   |
| CONTROLFILE_CREATED          | 控制文件创建时间                               |
| CONTROLFILE_SEQUENCE#        | 控制文件序列号                                 |
| CONTROLFILE_CHANGE#          | 控制文件的 SCN                                 |
| CONTROLFILE_TIME             | 控制文件时间戳                                 |
| OPEN_RESETLOGS               | 是否处于 OPEN RESETLOGS 模式                   |
| VERSION_TIME                 | 数据库版本时间                                 |
| OPEN_MODE                    | 数据库打开模式（READ WRITE / MOUNT / NOMOUNT） |
| PROTECTION_MODE              | 数据库保护模式（Data Guard 相关）              |
| PROTECTION_LEVEL             | 数据库保护级别                                 |
| REMOTE_ARCHIVE               | 是否开启远程归档                               |
| ACTIVATION#                  | 激活号（Data Guard 相关）                      |
| SWITCHOVER#                  | 切换编号（Data Guard 切换操作）                |
| DATABASE_ROLE                | 数据库角色（PRIMARY / STANDBY）                |
| ARCHIVELOG_CHANGE#           | 当前归档日志 SCN                               |
| ARCHIVELOG_COMPRESSION       | 归档日志压缩状态                               |
| SWITCHOVER_STATUS            | 切换状态（Data Guard）                         |
| DATAGUARD_BROKER             | Data Guard Broker 状态                         |
| GUARD_STATUS                 | 数据保护状态                                   |
| SUPPLEMENTAL_LOG_DATA_MIN    | 最小补充日志数据                               |
| SUPPLEMENTAL_LOG_DATA_PK     | 主键补充日志                                   |
| SUPPLEMENTAL_LOG_DATA_UI     | 唯一索引补充日志                               |
| FORCE_LOGGING                | 是否强制日志记录                               |
| PLATFORM_ID                  | 数据库平台 ID                                  |
| PLATFORM_NAME                | 数据库平台名称                                 |
| RECOVERY_TARGET_INCARNATION# | 恢复目标数据库编号                             |
| LAST_OPEN_INCARNATION#       | 最近一次打开数据库编号                         |
| CURRENT_SCN                  | 当前 SCN                                       |
| FLASHBACK_ON                 | 是否开启 Flashback                             |
| SUPPLEMENTAL_LOG_DATA_FK     | 外键补充日志                                   |
| SUPPLEMENTAL_LOG_DATA_ALL    | 全列补充日志                                   |
| DB_UNIQUE_NAME               | 数据库唯一名称                                 |
| STANDBY_BECAME_PRIMARY_SCN   | 备用库变为主库的 SCN                           |
| FS_FAILOVER_STATUS           | Fast-Start Failover 状态                       |
| FS_FAILOVER_CURRENT_TARGET   | 当前 FS 目标                                   |
| FS_FAILOVER_THRESHOLD        | FS 阈值                                        |
| FS_FAILOVER_OBSERVER_PRESENT | FS 观察者是否存在                              |
| FS_FAILOVER_OBSERVER_HOST    | FS 观察者主机                                  |
| CONTROLFILE_CONVERTED        | 控制文件是否转换                               |
| PRIMARY_DB_UNIQUE_NAME       | 主库唯一名称                                   |
| SUPPLEMENTAL_LOG_DATA_PL     | 部分日志策略                                   |
| MIN_REQUIRED_CAPTURE_CHANGE# | 最小采集 SCN（LogMiner 或 CDC 相关）           |



#### 3.1.1. 查询数据库归档模式

**描述**：检查数据库是否启用归档模式。

**SQL**：

```sql
SELECT LOG_MODE FROM V$DATABASE;
```

**输出示例**：

| LOG\_MODE  |
| ---------- |
| ARCHIVELOG |

#### 3.1.2. 查询当前 SCN

**描述**：获取数据库当前 SCN 值，用于增量日志定位和 LogMiner 查询。

**SQL**：

```sql
SELECT CURRENT_SCN FROM V$DATABASE;
```

**输出示例**：

| CURRENT\_SCN |
| :----------- |
| 123456789    |

#### 3.1.3. 查询归档日志

**描述**：查看归档日志文件信息，可按时间筛选。

**SQL**：

```sql
-- 全量归档日志
SELECT * FROM V$ARCHIVED_LOG;

-- 过去一小时归档日志
SELECT * FROM V$ARCHIVED_LOG 
WHERE COMPLETION_TIME > SYSDATE - 1/24 
ORDER BY COMPLETION_TIME;
```

**输出示例**：

| NAME                  | FIRST\_CHANGE# | NEXT\_CHANGE# | COMPLETION\_TIME    |
| --------------------- | -------------- | ------------- | ------------------- |
| /oradata/arch1\_1.arc | 100            | 200           | 2025-08-29 10:30:00 |
| /oradata/arch1\_2.arc | 201            | 300           | 2025-08-29 11:00:00 |



---

#### 3.1.4. 查询表级补充日志设置

**描述**：查看哪些表已开启全列补充日志。

**SQL**：

```sql
SELECT * FROM DBA_LOG_GROUPS WHERE LOG_GROUP_TYPE = 'ALL COLUMN LOGGING';
```

**输出示例**：

| TABLE\_NAME  | LOG\_GROUP\_TYPE   |
| ------------ | ------------------ |
| CG\_DEPO\_PE | ALL COLUMN LOGGING |
| CG\_ORDER    | ALL COLUMN LOGGING |

**参数说明**：

* `LOG_GROUP_TYPE`：日志类型

---

### 3.2.开启补充日志

#### 3.2.1. 启用数据库级别补充日志

**描述**：开启数据库级别的补充日志，为 LogMiner 做准备。

**SQL**：

```sql
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
```

**输出示例**：成功执行，无返回结果

**参数说明**：无

---

#### 3.2.2. 启用表级全字段补充日志

**描述**：为特定表开启全列补充日志。

**SQL**：

```sql
ALTER TABLE "模式"."表名" ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
```

**输出示例**：成功执行，无返回结果

**参数说明**：

* `"模式"`：表所属 schema
* `"表名"`：需要补充日志的表

---

#### 3.2.3. 启用模式下所有表的全字段补充日志

**描述**：循环为整个 schema 下所有表开启全列补充日志，带异常处理。

**SQL**：

```sql
BEGIN
   FOR t IN (SELECT table_name FROM all_tables WHERE owner = '模式') LOOP
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE 模式.' || t.table_name || ' ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS';
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(t.table_name || ' 已存在或失败: ' || SQLERRM);
      END;
   END LOOP;
END;
/
```

**输出示例**：

```
CG_DEPO_PE 已存在或失败: ORA-14053: supplemental log already exists
CG_ORDER 成功
```

**参数说明**：

* `模式`：schema 名

---

### 3.3.增量日志（LogMiner）

#### 3.3.1. 查询 redo log 文件位置

**描述**：查看数据库 redo log 文件路径及状态，为 LogMiner 添加日志做准备。

**SQL**：

```sql
SELECT * FROM V$LOGFILE;
```

**输出示例**：

| GROUP# | MEMBER              | STATUS   |
| ------ | ------------------- | -------- |
| 1      | /oradata/redo01.log | ACTIVE   |
| 2      | /oradata/redo02.log | INACTIVE |

**参数说明**：无

---

#### 3.3.2. 添加 redo log 文件到 LogMiner

**描述**：将 redo log 文件加入 LogMiner 会话。

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

---

#### 3.3.3. 查询已监控日志文件

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

---

#### 3.3.4. 启动 LogMiner

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

---

#### 3.3.5. 查询 LogMiner 内容

**描述**：查看指定表的增量变更。

**SQL**：

```sql
SELECT SCN, TIMESTAMP, OPERATION, TABLE_NAME, SQL_REDO, SQL_UNDO 
FROM V$LOGMNR_CONTENTS 
WHERE TABLE_NAME = 'CG_DEPO_PE'
ORDER BY TIMESTAMP DESC;
```

**输出示例**：

| SCN    | TIMESTAMP           | OPERATION | TABLE\_NAME  | SQL\_REDO                            | SQL\_UNDO                         |
| ------ | ------------------- | --------- | ------------ | ------------------------------------ | --------------------------------- |
| 123456 | 2025-08-29 11:10:00 | INSERT    | CG\_DEPO\_PE | INSERT INTO CG\_DEPO\_PE VALUES(...) | DELETE FROM CG\_DEPO\_PE WHERE... |

**参数说明**：

* `TABLE_NAME`：指定查询表名

---

#### 3.3.6. 停止 LogMiner

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

---

如果你需要，我可以帮你再画一张 **Oracle 归档日志 + LogMiner 流程图**，把整个“归档日志生成 → 补充日志 → redo 日志 → LogMiner 解析 → 查询增量变更”的流程可视化，会非常直观。

你希望我画吗？

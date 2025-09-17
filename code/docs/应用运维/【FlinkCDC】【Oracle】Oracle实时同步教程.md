---
title: 【FlinkCDC】【Oracle】Oracle实时同步教程
copyright: CC-BY-4.0
tags:
  - flink
  - flinkCDC
  - oracle
createTime: 2025/09/17 12:41:10
permalink: /blog/86skjl3u/
---

## 1.参考

**官方地址:**
https://flink.apache.org/

**官方文档地址:**
https://nightlies.apache.org/flink/

**github flinkcdc**

https://github.com/apache/flink-cdc

## 2.前置条件

**系统版本:**any

**软件依赖:**flink

**权限要求:**root

**网络要求:**any

**其他注意事项:**

## 3.环境准备

待完善 [Oracle安装](./引用路径文档.md)

[OracleBinLog开启](../数据库运维/Oracle/【Oracle】【BinLog】OracleLogmnr补全日志操作说明.md)

## 4.安装部署

待完善 [Flink环境安装](./引用路径文档.md)

## 5.配置说明

### 5.1.debezium

```markdown
"database.rule":"dml"
"debezium.poll.interval.ms":"500"
"debezium.heartbeat.interval.ms":"3000"
"database.history.kafka.recovery.poll.interval.ms":"3000"
"database.history.store.only.captured.tables.ddl":"cdc-true"
"log.mining.strategy":"online_catalog"
```

| 配置项                                             | 描述                                                         | 默认值 / 示例                |
| -------------------------------------------------- | ------------------------------------------------------------ | ---------------------------- |
| `database.hostname`                                | Oracle 数据库地址，用于连接源数据库                          | `127.0.0.1`                  |
| `database.port`                                    | Oracle 端口号                                                | `1521`                       |
| `database.user`                                    | 数据库用户名，用于读取 redo/归档日志                         | `cdc_user`                   |
| `database.password`                                | 数据库密码                                                   | `StrongPassword`             |
| `database.dbname`                                  | 指定 PDB 或 SID                                              | `ORCLPDB1`                   |
| `database.server.name`                             | 逻辑数据库标识，用于 Kafka topic 命名                        | `dbserver1`                  |
| `database.rule`                                    | 捕获操作类型，`dml` 表示只捕获 INSERT/UPDATE/DELETE          | `dml`                        |
| `debezium.poll.interval.ms`                        | redo 日志轮询间隔，每隔指定毫秒读取日志                      | `500`                        |
| `debezium.heartbeat.interval.ms`                   | 心跳事件发送间隔，用于更新 SCN/偏移                          | `3000`                       |
| `database.history.kafka.recovery.poll.interval.ms` | 恢复 Kafka schema/history topic 的轮询间隔                   | `3000`                       |
| `database.history.store.only.captured.tables.ddl`  | 只存储开启 CDC 的表的 DDL 到 history topic                   | `cdc-true`                   |
| `log.mining.strategy`                              | LogMiner 字典策略，`online_catalog` 表示使用在线字典解析 redo | `online_catalog`             |
| `snapshot.mode`                                    | 全量快照策略，决定启动时是否做初始全量快照                   | `initial`                    |
| `fetch.size`                                       | 批量读取数据大小，每次读取 redo/归档日志的行数               | `1024`                       |
| `table.include.list`                               | 捕获指定表的变更，按表名列表                                 | -                            |
| `table.exclude.list`                               | 排除表，避免日志量过大                                       | -                            |
| `decimal.handling.mode`                            | Decimal 类型解析方式                                         | `precise`                    |
| `time.precision.mode`                              | 时间类型解析精度                                             | `adaptive_time_microseconds` |
| `max.batch.size`                                   | 每次向下游发送的最大事件条数                                 | `2048`                       |
| `poll.interval.ms`                                 | Flink CDC 内部轮询间隔                                       | `500`                        |
| `log.mining.start.scn`                             | 从指定 SCN 开始捕获增量数据                                  | -                            |
| `log.mining.end.scn`                               | 可选，指定捕获结束 SCN                                       | -                            |
| `scan.incremental.snapshot.enabled`                | 是否开启增量快照模式                                         | `false`                      |

## 6.常用操作

## 7.排错与日志

### 7.1.未启用数据库级别补充日志

**报错日志**

```shell
Supplemental logging not properly configured Use: ALTER DATABASE ADD SUPPLEMENTAL LOG DATA
```

**原因**

* 当前源端数据源连接未启用数据库级别补充日志

**解决**

```sql
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
```

### 7.2.表LOG_MINING_FLUSH不存在

**报错日志**

```shell
Database table 'LOG_MINING_FLUSH' no longer exists, supplemental log check skipped
```

**原因**

* 当前源端用户无创建`LOG_MINING_FLUSH`表权限,建议使用新建CDC用户抽取源端业务数据

### 7.3.未开启全字段补全日志

**报错日志**

```shell
Database table '{}' not configured with supplemental logging (ALL) COLUMNS only explicitly changed columns will be captured. Use: ALTER TABLE {}.{} ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS
```

**原因**

* 当前表未开启全字段补全日志

**解决**

```sql
ALTER TABLE "模式"."表名" ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
```

## 8.升级与维护

## 9.附录
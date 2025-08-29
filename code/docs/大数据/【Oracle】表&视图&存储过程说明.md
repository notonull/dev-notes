## 1.表

## 2.视图

#### 动态性能视图

##### 2.1.参数说明

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

## 3.存储过程
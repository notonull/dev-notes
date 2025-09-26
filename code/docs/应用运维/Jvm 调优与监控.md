---
title: Jvm 调优与监控
copyright: CC-BY-4.0
tags:
  - linux
  - jvm
createTime: 2025/09/15 03:34:29
permalink: /blog/l90oqeea/
---

## 1.参考

[官方地址](https://www.oracle.com/)

[官方服务器版本下载地址](https://www.oracle.com/cn/java/technologies/downloads/)

## 2.Jvm调优

### 2.1. 大堆调优

```shell
nohup java \
  # ===== JVM 基础 =====
  -server \                                 # 使用 Server 模式 JVM，性能更优
  -XX:+UnlockExperimentalVMOptions \        # 解锁实验性参数，允许使用部分实验功能

  # ===== JVM 堆设置 =====
  -Xms20G \                                 # 初始堆大小 20G，避免启动时扩容
  -Xmx20G \                                 # 最大堆大小 20G，固定内存上限

  # ===== GC 设置 =====
  -XX:+UseG1GC \                            # 使用 G1 垃圾收集器（适合大堆）
  -XX:MaxGCPauseMillis=200 \                # 目标最大 GC 停顿时间 200ms
  -XX:+ParallelRefProcEnabled \             # 启用引用对象的并行处理，降低 STW 时间

  # ===== GC 日志输出 =====
  -XX:+PrintGC \                            # 打印 GC 简要日志
  -XX:+PrintGCDetails \                     # 打印 GC 详细日志
  -XX:+PrintGCTimeStamps \                  # 打印相对时间戳
  -XX:+PrintGCDateStamps \                  # 打印绝对时间戳（日期格式）
  -XX:+PrintGCApplicationStoppedTime \      # 打印应用因 GC 停顿的时间
  -XX:+PrintGCApplicationConcurrentTime \   # 打印应用并发运行时间
  -Xloggc:/opt/logs/demo/gc-$(date +%Y%m%d_%H%M%S).log \  # GC 日志文件路径（带时间戳）
  -XX:+UseGCLogFileRotation \               # 启用 GC 日志文件轮转
  -XX:NumberOfGCLogFiles=10 \               # 最多保留 10 个 GC 日志文件
  -XX:GCLogFileSize=200M \                  # 单个 GC 日志文件大小 200MB

  # ===== OOM Dump =====
  -XX:+HeapDumpOnOutOfMemoryError \         # OOM 时自动导出堆快照
  -XX:HeapDumpPath=/opt/logs/demo/heapdump-$(date +%Y%m%d_%H%M%S).hprof \  # 堆转储文件路径

  # ===== JMX 远程监控 =====
  -Dcom.sun.management.jmxremote \          # 启用 JMX
  -Dcom.sun.management.jmxremote.port=1808 \ # JMX 端口
  -Dcom.sun.management.jmxremote.authenticate=false \ # 关闭认证（有安全风险）
  -Dcom.sun.management.jmxremote.ssl=false \ # 关闭 SSL
  -Djava.rmi.server.hostname=127.0.0.1 \    # 指定 JMX 主机名（仅允许本机访问）

  # ===== 应用启动 =====
  -jar $completeAppname \                   # 启动应用 Jar 包
  > /dev/null 2>&1 &                        # 屏蔽日志输出（建议改为写入日志文件）
```



| 类型                | 参数                                                | 作用                             | 对性能影响        | 备注                            |
| ------------------- | --------------------------------------------------- | -------------------------------- | ----------------- | ------------------------------- |
| **JVM 基础**        | `-server`                                           | 启用 Server JVM                  | 正面（更佳优化）  | 生产常用                        |
|                     | `-XX:+UnlockExperimentalVMOptions`                  | 解锁实验性参数                   | 无                | 允许使用实验功能                |
| **堆内存设置**      | `-Xms20G`                                           | 初始堆大小                       | 无                | 避免启动时扩容停顿              |
|                     | `-Xmx20G`                                           | 最大堆大小                       | 无                | 固定堆大小，生产常用            |
| **GC 算法与调优**   | `-XX:+UseG1GC`                                      | 使用 G1 GC                       | 无（大堆更优）    | 适合 >8G 堆                     |
|                     | `-XX:MaxGCPauseMillis=200`                          | 目标最大停顿 200ms               | 可能增加 CPU 占用 | 仅为目标，不保证                |
|                     | `-XX:+ParallelRefProcEnabled`                       | 并行处理引用对象                 | 小幅 CPU 占用     | 建议开启                        |
| **GC 日志（打印）** | `-XX:+PrintGC`                                      | 打印简要 GC 日志                 | 轻微              | 排查必备                        |
|                     | `-XX:+PrintGCDetails`                               | 打印详细 GC 信息                 | 轻微              | 包含内存分代信息                |
|                     | `-XX:+PrintGCTimeStamps`                            | 打印相对时间戳                   | 无                | 用于分析顺序                    |
|                     | `-XX:+PrintGCDateStamps`                            | 打印日期时间戳                   | 无                | 长期运行必备                    |
|                     | `-XX:+PrintGCApplicationStoppedTime`                | 打印应用因 GC 停顿的时间         | 无                | 用于评估 STW                    |
|                     | `-XX:+PrintGCApplicationConcurrentTime`             | 打印应用并发时间                 | 无                | 分析并发 GC                     |
| **GC 日志（文件）** | `-Xloggc:/opt/logs/demo/gc-$(date ...).log`         | 指定 GC 日志文件路径（带时间戳） | 无                | 启动即命名，便于归档            |
|                     | `-XX:+UseGCLogFileRotation`                         | 启用 GC 日志轮转                 | 无                | 防止单文件过大                  |
|                     | `-XX:NumberOfGCLogFiles=10`                         | 保留日志文件个数                 | 无                | 配合轮转使用                    |
|                     | `-XX:GCLogFileSize=200M`                            | 单个 GC 日志最大大小             | 无                | 单位 MB                         |
| **OOM Dump**        | `-XX:+HeapDumpOnOutOfMemoryError`                   | OOM 时自动生成堆快照             | OOM 时磁盘写入大  | 用于分析内存泄漏                |
|                     | `-XX:HeapDumpPath=/opt/logs/demo/...hprof`          | Heap dump 保存路径（带时间戳）   | 无                | 避免覆盖                        |
| **JMX 远程监控**    | `-Dcom.sun.management.jmxremote`                    | 开启 JMX 服务                    | 无                | 用于监控                        |
|                     | `-Dcom.sun.management.jmxremote.port=1808`          | JMX 监听端口                     | 无                | 内网使用                        |
|                     | `-Dcom.sun.management.jmxremote.authenticate=false` | 关闭认证                         | 无（安全风险）    | 仅本机调试可用，生产建议开启    |
|                     | `-Dcom.sun.management.jmxremote.ssl=false`          | 关闭 SSL                         | 无                | 简化配置                        |
|                     | `-Djava.rmi.server.hostname=127.0.0.1`              | 指定 RMI 主机名（绑定回环地址）  | 无                | 防止外部访问，远程需改为实际 IP |
| **启动方式 / 输出** | `nohup ... &`                                       | 后台运行                         | 无                | 常见生产方式                    |
|                     | `-jar $completeAppname`                             | 启动 jar 包                      | 无                | 替换为实际路径                  |
|                     | `> /dev/null 2>&1`                                  | 屏蔽 stdout/stderr               | 无                | 建议改为写入日志文件            |

### 2.2.Jvm监控


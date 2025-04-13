---
title: 【Java】程序启动脚本模板
copyright: CC-BY-4.0
tags:
  - java
  - 模板

---

## 内容

### 1.linux

#### 1.1.app.sh

```shell
#!/bin/bash
## 作者: aGeng
## 更新日期: 2024-08-23
## 版本: 1.3.0

version="1.3.0"

appName=$2
port=8998
debugPort=58802

# 如果没有指定应用名，自动选择最新的 .jar 文件
if [ -z "$appName" ]; then
    appName=$(ls -t | grep .jar$ | head -n1)
fi

# 获取应用的进程 ID (PID)，根据端口或应用名
function getAppPid() {
    if [ -n "$port" ]; then
        # 如果指定了端口号，则通过端口号查找进程 PID
        appId=$(lsof -t -i:$port)
    else
        # 如果没有指定端口号，则通过应用名查找进程 PID
        appId=$(ps -ef | grep java | grep "$appName" | awk '{print $2}')
    fi
    echo $appId
}


# 启动应用
function start() {
     appId=$(getAppPid)
    if [ -n "$appId" ]; then
        echo "应用 $appName 可能已经在端口 $port 上运行 (PID: $appId)，请检查。"
    else
        if [ -n "$port" ]; then
            echo "正在启动 $appName... 使用端口 $port"
            nohup java -jar ./$appName -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./app-log -Xms4G -Xmx4G -Dserver.port=$port > /dev/null 2>&1 &
        else
            echo "正在启动 $appName..."
            # 如果没有指定端口号，则不添加 -Dserver.port
            nohup java -jar ./$appName -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./app-log -Xms4G -Xmx4G > /dev/null 2>&1 &
        fi
         # 等待直到应用启动并监听端口
        echo "等待应用启动..."
        # 这里等待最多 120 秒，检查端口是否被占用
        for i in {1..120}; do
            sleep 1
            # 检查端口是否被占用
            appId=$(lsof -t -i:$port)
            if [ -n "$appId" ]; then
                echo "$appName 启动成功，PID: $appId，日志路径: ./app-log"
                return 0
            fi
            echo "等待应用启动... ($i/120)"
        done

        # 如果超过60秒应用还没启动，提示失败
        echo "$appName 超过监听时间请手动监听，端口 $port "
    fi
}

# 启动调试模式
function debug() {
     appId=$(getAppPid)
    if [ -n "$appId" ]; then
        echo "应用 $appName 可能已经在端口 $port 上运行 (PID: $appId)，请检查。"
    else
        echo "正在启动 $appName (调试模式)..."
        nohup java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=$debugPort -jar ./$appName -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./app-log -Xms1G -Xmx1G > /dev/null 2>&1 &
        echo "$appName 调试模式启动成功，调试端口: $debugPort，日志路径: ./app-log"
    fi
}

# 停止应用
function stop() {
    appId=$(getAppPid)
    if [ -z "$appId" ]; then
        echo "$appName 可能没有运行，请检查。"
    else
        echo "正在停止 $appName (PID: $appId)..."
        kill -9 $appId
        echo "$appName 已停止。"
    fi
}

# 重启应用
function restart() {
    stop
    start
}

# 查看应用状态
function status() {
    appId=$(getAppPid)
    if [ -z "$appId" ]; then
        echo -e "\033[31m $appName 未运行 \033[0m"
    else
        echo -e "\033[32m $appName 正在运行 (PID: $appId) \033[0m"
    fi
}

# 查看日志
function log() {
    echo "正在查看日志 ./app-log/log_total.log..."
    tail -f ./app-log/log_total.log
}

# 显示使用说明
function usage() {
    echo "Usage: $0 {start|debug|stop|restart|status|log}"
    echo "Example: $0 start"
    exit 1
}

# 解析脚本命令
case $1 in
    start)
        start
        ;;
    debug)
        debug
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    log)
        log
        ;;
    *)
        usage
        ;;
esac
```


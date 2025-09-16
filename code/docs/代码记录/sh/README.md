# Docker Compose 模块化部署脚本

## 概述

这是一个基于模块化架构的Docker服务自动化部署脚本系统，将原来的单体脚本重构为主脚本 + 服务子脚本的架构。

## 文件结构

```
.
├── docker-compose-script.sh    # 主运行脚本（协调器）
├── docker-compose-jenkins.sh   # Jenkins服务脚本
├── docker-compose-mysql.sh     # MySQL服务脚本
├── docker-compose-mongodb.sh   # MongoDB服务脚本
├── docker-compose-redis.sh     # Redis服务脚本
├── docker-compose-minio.sh     # MinIO服务脚本
├── docker-compose-nacos.sh     # Nacos服务脚本
├── docker-compose-nexus.sh     # Nexus服务脚本
├── docker-compose-yapi.sh      # YApi服务脚本
├── demo.sh                     # 演示脚本
└── README.md                   # 说明文档
```

## 架构特点

### 1. 主脚本 (`docker-compose-script.sh`)
- **统一入口**：所有操作的统一入口点
- **服务发现**：自动发现可用的服务脚本
- **协调管理**：协调多个服务的安装和管理
- **通用功能**：提供日志、状态检查、Docker环境检查等通用功能
- **智能调用**：根据命令智能调用相应的服务脚本方法

### 2. 服务脚本 (`docker-compose-[服务名].sh`)
- **标准化接口**：每个服务脚本都提供标准的 `install()` 函数
- **独立部署**：可以单独管理特定服务
- **镜像管理**：包含 `check_and_pull_image()` 和 `get_image()` 函数
- **模块化设计**：易于添加新服务或修改现有服务

## 使用方法

### 基础命令

```bash
# 显示帮助信息
./docker-compose-script.sh help

# 安装所有服务
./docker-compose-script.sh install

# 安装指定服务
./docker-compose-script.sh install jenkins
./docker-compose-script.sh install mysql

# 启动所有服务
./docker-compose-script.sh up

# 启动指定服务
./docker-compose-script.sh up jenkins

# 停止所有服务
./docker-compose-script.sh down

# 停止指定服务
./docker-compose-script.sh down jenkins

# 查看服务日志
./docker-compose-script.sh logs jenkins

# 查看所有服务状态
./docker-compose-script.sh status

# 卸载服务（危险操作）
./docker-compose-script.sh uninstall jenkins
```

### Docker状态命令

```bash
# 查看所有Docker服务状态
./docker-compose-script.sh docker status

# 查看指定服务状态
./docker-compose-script.sh docker status jenkins
```

## 支持的服务

当前支持以下服务：

| 服务名 | 容器名 | 端口 | 默认认证 |
|--------|--------|------|----------|
| jenkins | jenkins | 8080, 50000 | 初始密码文件 |
| mysql | mysql | 3306 | root/123456 |
| mongodb | mongodb | 27017 | root/123456 |
| redis | redis | 6379 | 密码: 123456 |
| minio | minio | 9000, 9090 | admin/admin123 |
| nacos | nacos | 8848, 9080, 9848 | nacos/nacos |
| nexus | nexus | 8081 | admin/123456 |
| yapi | yapi | 3000 | admin@yapi.com/123456 |

## 添加新服务

要添加新服务，创建 `docker-compose-[服务名].sh` 文件，包含以下标准函数：

```bash
#!/bin/bash

# 检查并拉取镜像
check_and_pull_image() {
    # 镜像检查和拉取逻辑
}

# 服务安装函数
install() {
    # 服务部署逻辑
}

# 获取镜像名
get_image() {
    echo "your-image:tag"
}
```

## 架构优势

1. **模块化**：每个服务独立管理，便于维护
2. **可扩展**：添加新服务只需创建对应脚本文件
3. **统一管理**：主脚本提供统一的管理接口
4. **智能发现**：自动发现可用服务，无需手动配置
5. **标准化**：所有服务脚本遵循统一的接口标准
6. **灵活性**：支持单独操作特定服务或批量操作

## 注意事项

1. 确保以root权限运行脚本
2. 确保已安装Docker和Docker Compose
3. 服务脚本文件需要可执行权限
4. 服务间存在依赖关系时注意安装顺序（如Nacos依赖MySQL）

## 故障排除

- 检查Docker服务状态：`systemctl status docker`
- 查看容器日志：`docker logs [容器名]`
- 检查端口占用：`netstat -tlnp | grep [端口号]`
- 重启服务：`./docker-compose-script.sh down [服务名] && ./docker-compose-script.sh up [服务名]`
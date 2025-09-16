# Docker Compose 部署脚本系统

这是一个模块化的Docker服务部署脚本系统，支持统一管理多个Docker服务的生命周期。

## 目录结构

```
.
├── docker-compose-deploy.sh    # 主脚本 (v2.0)
├── deploy/                     # 子脚本目录
│   └── jenkins.sh             # Jenkins服务部署脚本 (v2.0)
├── lib/                        # 🆕 公共库目录
│   ├── logger.sh              # 日志工具库
│   ├── docker_utils.sh        # Docker操作库
│   ├── system_utils.sh        # 系统工具库
│   └── config_utils.sh        # 配置管理库
├── README.md                  # 说明文档
├── USAGE_EXAMPLES.md          # 使用示例
└── DEMO.md                    # 重构演示文档
```

## 功能特性

### 主脚本功能
- **统一管理**: 通过主脚本统一管理所有子服务脚本
- **批量操作**: 支持对所有服务执行批量操作
- **安全确认**: 危险操作需要用户确认
- **模块化设计**: 子脚本可独立运行
- **日志系统**: 统一的彩色日志输出

### 子脚本功能
- **标准化配置**: 统一的变量命名规范
- **完整生命周期**: 支持服务的完整生命周期管理
- **状态检查**: 实时获取服务状态
- **错误处理**: 完善的错误检查和处理

## 使用方法

### 主脚本命令

```bash
# 显示帮助信息
./docker-compose-deploy.sh help

# 查看配置信息
./docker-compose-deploy.sh config           # 所有服务
./docker-compose-deploy.sh config jenkins   # 指定服务

# 拉取镜像 (需要确认)
./docker-compose-deploy.sh pull             # 所有服务
./docker-compose-deploy.sh pull jenkins     # 指定服务

# 安装服务 (需要确认)
./docker-compose-deploy.sh install          # 所有服务
./docker-compose-deploy.sh install jenkins  # 指定服务

# 启动服务 (需要确认)
./docker-compose-deploy.sh up               # 所有服务
./docker-compose-deploy.sh up jenkins       # 指定服务

# 停止服务 (需要确认)
./docker-compose-deploy.sh down             # 所有服务
./docker-compose-deploy.sh down jenkins     # 指定服务

# 卸载服务 (需要确认)
./docker-compose-deploy.sh uninstall        # 所有服务
./docker-compose-deploy.sh uninstall jenkins # 指定服务

# 删除镜像 (需要确认)
./docker-compose-deploy.sh rmi              # 所有服务
./docker-compose-deploy.sh rmi jenkins      # 指定服务

# 查看日志 (必须指定服务)
./docker-compose-deploy.sh logs jenkins

# 查看服务信息
./docker-compose-deploy.sh info             # 所有服务
./docker-compose-deploy.sh info jenkins     # 指定服务
```

### 子脚本独立使用

```bash
# 可以直接运行子脚本
./deploy/jenkins.sh install
./deploy/jenkins.sh info
./deploy/jenkins.sh logs
```

## 配置说明

### 变量命名规范

#### 基础变量 (base_ 前缀)
- `base_image_name`: Docker镜像名称
- `base_container_name`: 容器名称
- `base_install_path`: 安装路径
- `base_ip`: 服务器IP地址

#### 环境变量 (env_ 前缀)
- `env_ports`: 端口映射数组
- `env_volumes`: 卷挂载数组
- `env_environment`: 环境变量数组

### 日志系统

提供统一的日志函数：
- `log_info`: 信息日志 (绿色)
- `log_warn`: 警告日志 (黄色)
- `log_error`: 错误日志 (红色)
- `log_step`: 步骤日志 (蓝色)

### 服务状态

- **运行中** (绿色): 容器正在运行
- **已停止** (黄色): 容器已停止
- **未安装** (红色): 服务未安装
- **未知状态** (红色): 无法确定状态

## Jenkins 服务说明

### 默认配置
- **镜像**: jenkins/jenkins:lts
- **端口**: 8080 (Web界面), 50000 (JNLP)
- **数据目录**: /opt/server/jenkins/data
- **日志目录**: /opt/server/jenkins/logs
- **时区**: Asia/Shanghai

### 安装后操作
1. 访问 http://您的IP:8080/
2. 使用显示的初始管理员密码进行初始化
3. 安装推荐的插件
4. 创建管理员用户

## 扩展新服务

### 1. 创建子脚本
在 `deploy/` 目录下创建新的服务脚本，例如 `deploy/nginx.sh`

### 2. 注册服务
在主脚本的 `REGISTERED_SCRIPTS` 中添加映射：
```bash
REGISTERED_SCRIPTS["nginx"]="deploy/nginx.sh"
```

### 3. 实现标准函数
子脚本需要实现以下函数：
- `cmd_config`: 显示配置
- `cmd_pull`: 拉取镜像
- `cmd_install`: 安装服务
- `cmd_uninstall`: 卸载服务
- `cmd_down`: 停止服务
- `cmd_up`: 启动服务
- `cmd_rmi`: 删除镜像
- `cmd_logs`: 查看日志
- `cmd_info`: 显示信息
- `cmd_help`: 显示帮助

## 系统要求

- Linux/Unix 系统
- Bash 4.0+
- Docker
- Docker Compose

## 注意事项

1. 批量操作时会要求用户确认，确保安全性
2. 子脚本可以独立运行，不依赖主脚本
3. 所有危险操作都有确认提示
4. 日志会显示时间戳和彩色标识
5. 支持通过环境变量自定义配置

## 故障排除

### 权限问题
```bash
chmod +x docker-compose-deploy.sh
chmod +x deploy/*.sh
```

### Docker权限问题
```bash
sudo usermod -aG docker $USER
# 重新登录或执行
newgrp docker
```

### 服务端口冲突
检查并修改子脚本中的端口配置，或停止冲突的服务。
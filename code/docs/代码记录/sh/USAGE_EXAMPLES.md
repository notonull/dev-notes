# 使用示例

## 快速开始

### 1. 基本使用流程

```bash
# 查看帮助
./docker-compose-deploy.sh help

# 查看Jenkins配置
./docker-compose-deploy.sh config jenkins

# 安装Jenkins服务
./docker-compose-deploy.sh install jenkins

# 查看Jenkins状态
./docker-compose-deploy.sh info jenkins

# 查看Jenkins日志
./docker-compose-deploy.sh logs jenkins

# 停止Jenkins服务
./docker-compose-deploy.sh down jenkins

# 启动Jenkins服务
./docker-compose-deploy.sh up jenkins

# 完全卸载Jenkins
./docker-compose-deploy.sh uninstall jenkins
```

### 2. 批量操作示例

```bash
# 查看所有服务配置
./docker-compose-deploy.sh config

# 安装所有服务（需要确认）
./docker-compose-deploy.sh install

# 启动所有服务（需要确认）
./docker-compose-deploy.sh up

# 查看所有服务状态
./docker-compose-deploy.sh info

# 停止所有服务（需要确认）
./docker-compose-deploy.sh down
```

### 3. 独立使用子脚本

```bash
# 直接使用Jenkins脚本
./deploy/jenkins.sh config
./deploy/jenkins.sh install
./deploy/jenkins.sh info
./deploy/jenkins.sh logs
```

## 实际部署示例

### Jenkins CI/CD 服务部署

1. **查看配置信息**
```bash
./docker-compose-deploy.sh config jenkins
```
输出示例：
```
==========================================
Jenkins 服务配置信息
==========================================
镜像名称: jenkins/jenkins:lts
容器名称: jenkins
安装路径: /opt/server/jenkins
服务器IP: 192.168.1.100
端口映射:
  - 8080:8080
  - 50000:50000
卷挂载:
  - /opt/server/jenkins/data:/var/jenkins_home
  - /opt/server/jenkins/logs:/var/log/jenkins
环境变量:
  - TZ=Asia/Shanghai
==========================================
```

2. **安装服务**
```bash
./docker-compose-deploy.sh install jenkins
```
安装过程：
- 检查Docker环境
- 拉取jenkins/jenkins:lts镜像
- 创建目录结构 (/opt/server/jenkins/{data,logs})
- 生成docker-compose.yml文件
- 启动服务
- 显示初始管理员密码

3. **查看服务状态**
```bash
./docker-compose-deploy.sh info jenkins
```
输出示例：
```
==========================================
Jenkins 服务信息
==========================================
镜像名称: jenkins/jenkins:lts
容器名称: jenkins
状态: 运行中
端口映射:
  - 8080:8080
  - 50000:50000
挂载路径: /opt/server/jenkins
环境变量:
  - TZ=Asia/Shanghai
访问URL: http://192.168.1.100:8080/
初始管理员密码: a1b2c3d4e5f6g7h8i9j0
容器信息:
NAMES     STATUS              PORTS
jenkins   Up 5 minutes        0.0.0.0:8080->8080/tcp, 0.0.0.0:50000->50000/tcp
==========================================
```

## 生成的文件结构

安装完成后的目录结构：
```
/opt/server/jenkins/
├── docker-compose.yml      # Docker Compose配置文件
├── data/                   # Jenkins数据目录
│   ├── secrets/
│   │   └── initialAdminPassword  # 初始密码
│   ├── plugins/            # 插件目录
│   ├── jobs/              # 任务配置
│   └── ...                # 其他Jenkins数据
└── logs/                  # 日志目录
```

## docker-compose.yml 示例

生成的Jenkins配置文件：
```yaml
version: "3.9"

services:
  jenkins:
    image: jenkins/jenkins:lts
    privileged: true
    container_name: jenkins
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    environment:
      TZ: Asia/Shanghai
    volumes:
      - /opt/server/jenkins/data:/var/jenkins_home
      - /opt/server/jenkins/logs:/var/log/jenkins
    restart: unless-stopped
```

## 常见操作场景

### 场景1：首次部署Jenkins
```bash
# 1. 查看配置确认无误
./docker-compose-deploy.sh config jenkins

# 2. 安装Jenkins
./docker-compose-deploy.sh install jenkins

# 3. 等待启动完成，查看初始密码
./docker-compose-deploy.sh info jenkins

# 4. 访问Web界面进行初始化
# http://你的IP:8080/
```

### 场景2：维护操作
```bash
# 查看实时日志
./docker-compose-deploy.sh logs jenkins

# 重启服务
./docker-compose-deploy.sh down jenkins
./docker-compose-deploy.sh up jenkins

# 更新Jenkins
./docker-compose-deploy.sh down jenkins
./docker-compose-deploy.sh pull jenkins
./docker-compose-deploy.sh up jenkins
```

### 场景3：完全清理
```bash
# 停止并删除容器、镜像、数据
./docker-compose-deploy.sh uninstall jenkins
```

## 错误处理示例

### Docker未安装
```bash
[ERROR] 2024-01-15 10:30:00 - Docker 未安装或不在PATH中
```

### 端口冲突
```bash
[ERROR] 2024-01-15 10:30:00 - Jenkins 服务启动失败
# 解决：检查8080端口是否被占用
sudo netstat -tlnp | grep :8080
```

### 权限问题
```bash
[ERROR] 2024-01-15 10:30:00 - 无法创建目录: /opt/server/jenkins
# 解决：使用sudo或修改目录权限
sudo mkdir -p /opt/server/jenkins
sudo chown $USER:$USER /opt/server/jenkins
```

## 扩展其他服务

### 添加Nginx服务示例

1. **创建nginx.sh**
```bash
cp deploy/jenkins.sh deploy/nginx.sh
# 修改配置变量
```

2. **注册服务**
在主脚本中添加：
```bash
REGISTERED_SCRIPTS["nginx"]="deploy/nginx.sh"
```

3. **使用新服务**
```bash
./docker-compose-deploy.sh install nginx
./docker-compose-deploy.sh info nginx
```

## 日志输出示例

脚本运行时的彩色日志输出：
```bash
[STEP] 2024-01-15 10:30:00 - 开始部署Jenkins服务...
[INFO] 2024-01-15 10:30:01 - 镜像已存在: jenkins/jenkins:lts
[INFO] 2024-01-15 10:30:01 - 创建Jenkins目录结构...
[INFO] 2024-01-15 10:30:02 - 创建docker-compose.yml文件...
[INFO] 2024-01-15 10:30:02 - docker-compose.yml文件创建完成
[INFO] 2024-01-15 10:30:02 - 启动Jenkins服务...
[INFO] 2024-01-15 10:30:05 - Jenkins服务部署成功！
[INFO] 2024-01-15 10:30:05 - 访问地址: http://192.168.1.100:8080/
[INFO] 2024-01-15 10:30:05 - 等待Jenkins服务完全启动...
[INFO] 2024-01-15 10:30:35 - Jenkins初始管理员密码: a1b2c3d4e5f6g7h8i9j0
```
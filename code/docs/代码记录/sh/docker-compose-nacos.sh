#!/bin/bash

# Nacos服务部署脚本
# 作者: Generated Script
# 服务: Nacos

# 检查镜像是否存在，不存在则拉取
check_and_pull_image() {
    local image_name=$1
    local image_exists=$(docker images -q "$image_name" 2>/dev/null)
    
    if [ -z "$image_exists" ]; then
        log_info "镜像 $image_name 不存在，开始拉取..."
        docker pull "$image_name"
        if [ $? -eq 0 ]; then
            log_info "镜像 $image_name 拉取成功"
        else
            log_error "镜像 $image_name 拉取失败"
            return 1
        fi
    else
        log_info "镜像 $image_name 已存在，跳过拉取"
    fi
}

# Nacos服务安装
install() {
    log_step "开始部署Nacos服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "nacos/nacos-server:latest"
    
    # 创建目录
    log_info "创建Nacos目录结构..."
    mkdir -p /opt/server/nacos/{data,logs}
    
    # 创建docker-compose.yml
    log_info "创建Nacos docker-compose.yml..."
    cat > /opt/server/nacos/docker-compose.yml << 'EOF'
version: "3.9"

services:
  nacos:
    image: nacos/nacos-server:latest
    container_name: nacos
    environment:
      - MODE=standalone
      - SPRING_DATASOURCE_PLATFORM=mysql
      - MYSQL_SERVICE_HOST=192.168.1.12
      - MYSQL_SERVICE_DB_NAME=nacos
      - MYSQL_SERVICE_PORT=3306
      - MYSQL_SERVICE_USER=root
      - MYSQL_SERVICE_PASSWORD=123456
      - MYSQL_SERVICE_DB_PARAM=characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
      - NACOS_AUTH_TOKEN=WDdrUHFYOXZWMnJZOFRXOEZuTDZOQXhQd0I1Y0gxZFEyeEE5ZVI0dU04aUs3b1AzdyN2TjJsVjBqRzVmVA==
      - NACOS_AUTH_IDENTITY_KEY=nacos
      - NACOS_AUTH_IDENTITY_VALUE=nacos
    ports:
      - "9080:8080"   # 内部 API（可选）
      - "8848:8848"   # 控制台 / 配置中心 / 服务发现
      - "9848:9848"   # gRPC 通道
    volumes:
      - /opt/server/nacos/data:/home/nacos/nacos-data
      - /opt/server/nacos/logs:/home/nacos/logs
    restart: unless-stopped
EOF
    
    # 启动服务
    log_info "启动Nacos服务..."
    cd /opt/server/nacos
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "Nacos服务部署成功！访问地址: http://192.168.1.12:9080/"
        log_info "认证信息: nacos/nacos"
    else
        log_error "Nacos服务部署失败"
        return 1
    fi
}

# 获取镜像名
get_image() {
    echo "nacos/nacos-server:latest"
}
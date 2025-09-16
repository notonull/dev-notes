#!/bin/bash

# YApi服务部署脚本
# 作者: Generated Script
# 服务: YApi

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

# YApi服务安装
install() {
    log_step "开始部署YApi服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "jayfong/yapi:latest"
    
    # 创建目录
    log_info "创建YApi目录结构..."
    mkdir -p /opt/server/yapi
    
    # 创建docker-compose.yml
    log_info "创建YApi docker-compose.yml..."
    cat > /opt/server/yapi/docker-compose.yml << 'EOF'
version: '3.9'

services:
  yapi:
    image: jayfong/yapi:latest
    container_name: yapi
    ports:
      - 3000:3000
    environment:
      - YAPI_ADMIN_ACCOUNT=admin@yapi.com 
      - YAPI_ADMIN_PASSWORD=123456
      - YAPI_CLOSE_REGISTER=true
      - YAPI_DB_SERVERNAME=192.168.1.12
      - YAPI_DB_PORT=27017
      - YAPI_DB_DATABASE=yapi
      - YAPI_DB_USER=root
      - YAPI_DB_PASS=123456
      - YAPI_DB_AUTH_SOURCE=admin
    restart: unless-stopped
EOF
    
    # 启动服务
    log_info "启动YApi服务..."
    cd /opt/server/yapi
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "YApi服务部署成功！访问地址: http://192.168.1.12:3000/"
        log_info "认证信息: admin@yapi.com/123456"
    else
        log_error "YApi服务部署失败"
        return 1
    fi
}

# 获取镜像名
get_image() {
    echo "jayfong/yapi:latest"
}
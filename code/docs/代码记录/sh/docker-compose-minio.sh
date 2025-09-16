#!/bin/bash

# MinIO服务部署脚本
# 作者: Generated Script
# 服务: MinIO

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

# MinIO服务安装
install() {
    log_step "开始部署MinIO服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "minio/minio:latest"
    
    # 创建目录
    log_info "创建MinIO目录结构..."
    mkdir -p /opt/server/minio/{data,config}
    
    # 创建docker-compose.yml
    log_info "创建MinIO docker-compose.yml..."
    cat > /opt/server/minio/docker-compose.yml << 'EOF'
version: "3.9"

services:
  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9090:9090"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: admin123
    volumes:
      - /opt/server/minio/data:/data
      - /opt/server/minio/config:/root/.minio
    command: server /data --console-address ":9090"
EOF
    
    # 启动服务
    log_info "启动MinIO服务..."
    cd /opt/server/minio
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "MinIO服务部署成功！访问地址: http://192.168.1.12:9000/"
        log_info "控制台地址: http://192.168.1.12:9090/"
        log_info "认证信息: admin/admin123"
    else
        log_error "MinIO服务部署失败"
        return 1
    fi
}

# 获取镜像名
get_image() {
    echo "minio/minio:latest"
}
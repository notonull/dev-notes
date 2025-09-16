#!/bin/bash

# Nexus服务部署脚本
# 作者: Generated Script
# 服务: Nexus

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

# Nexus服务安装
install() {
    log_step "开始部署Nexus服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "sonatype/nexus3:latest"
    
    # 创建目录
    log_info "创建Nexus目录结构..."
    mkdir -p /opt/server/nexus/data
    
    # 创建docker-compose.yml
    log_info "创建Nexus docker-compose.yml..."
    cat > /opt/server/nexus/docker-compose.yml << 'EOF'
version: "3.9"
services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    ports:
      - "8081:8081"
    volumes:
      - /opt/server/nexus/data:/nexus-data
    environment:
      TZ: Asia/Shanghai
    restart: unless-stopped
EOF
    
    # 启动服务
    log_info "启动Nexus服务..."
    cd /opt/server/nexus
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "Nexus服务部署成功！访问地址: http://192.168.1.12:8081/"
        log_info "认证信息: admin/123456"
        log_warn "首次启动可能需要几分钟时间，请耐心等待"
    else
        log_error "Nexus服务部署失败"
        return 1
    fi
}

# 获取镜像名
get_image() {
    echo "sonatype/nexus3:latest"
}
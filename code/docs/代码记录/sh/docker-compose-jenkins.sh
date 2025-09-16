#!/bin/bash

# Jenkins服务部署脚本
# 作者: Generated Script
# 服务: Jenkins

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

# Jenkins服务安装
install() {
    log_step "开始部署Jenkins服务..."
    
    # 检查并拉取镜像
    check_and_pull_image "jenkins/jenkins:lts"
    
    # 创建目录
    log_info "创建Jenkins目录结构..."
    mkdir -p /opt/server/jenkins/{data,logs}
    
    # 创建docker-compose.yml
    log_info "创建Jenkins docker-compose.yml..."
    cat > /opt/server/jenkins/docker-compose.yml << 'EOF'
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
EOF
    
    # 启动服务
    log_info "启动Jenkins服务..."
    cd /opt/server/jenkins
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_info "Jenkins服务部署成功！访问地址: http://192.168.1.12:8080/"
        log_info "等待Jenkins服务完全启动..."
        sleep 30
        
        # 获取Jenkins初始管理员密码
        if [ -f "/opt/server/jenkins/data/secrets/initialAdminPassword" ]; then
            initial_password=$(cat /opt/server/jenkins/data/secrets/initialAdminPassword)
            log_info "=========================================="
            log_info "Jenkins初始管理员密码: $initial_password"
            log_info "=========================================="
            log_info "请复制上面的密码用于Jenkins初始化配置"
        else
            log_warn "Jenkins初始密码文件未找到，请稍后查看或等待服务完全启动"
            log_info "您也可以手动查看: cat /opt/server/jenkins/data/secrets/initialAdminPassword"
        fi
        
        log_info "首次访问需要使用上面的初始密码进行配置"
    else
        log_error "Jenkins服务部署失败"
        return 1
    fi
}

# 获取镜像名
get_image() {
    echo "jenkins/jenkins:lts"
}
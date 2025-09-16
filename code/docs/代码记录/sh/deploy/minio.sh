#!/bin/bash

# MinIO 部署脚本 - 子脚本
# 版本: 2.0
# 描述: MinIO 对象存储服务部署脚本

set -euo pipefail

# 脚本目录 - 使用主脚本传递的路径或自动检测
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
LIB_DIR="${LIB_DIR:-${SCRIPT_DIR}/lib}"

# 加载公共库
source "${LIB_DIR}/logger.sh"
source "${LIB_DIR}/docker_utils.sh"
source "${LIB_DIR}/system_utils.sh"
source "${LIB_DIR}/config_utils.sh"

# ============================================
# 服务配置定义
# ============================================

# 基础配置 (统一前缀: base_)
base_image_name="minio/minio:latest"
base_container_name="minio"
base_install_path="/opt/server/minio"
base_ip=$(get_local_ip)

# 端口配置数组 (格式: "宿主机端口:容器端口")
declare -a env_ports=(
    "9000:9000"   # API端口
    "9090:9090"   # 控制台端口
)

# 卷挂载配置数组 (格式: "宿主机路径:容器路径")
declare -a env_volumes=(
    "${base_install_path}/data:/data"
    "${base_install_path}/config:/root/.minio"
)

# 环境变量配置数组 (格式: "变量名=值")
declare -a env_environment=(
    "MINIO_ROOT_USER=admin"
    "MINIO_ROOT_PASSWORD=admin123"
)

# ============================================
# 服务信息获取
# ============================================

# 获取服务URL
get_service_urls() {
    local urls=()
    for port_mapping in "${env_ports[@]}"; do
        local host_port=$(echo "$port_mapping" | cut -d':' -f1)
        if [[ "$host_port" == "9000" ]]; then
            urls+=("http://${base_ip}:${host_port}/")
        elif [[ "$host_port" == "9090" ]]; then
            urls+=("http://${base_ip}:${host_port}/ (控制台)")
        fi
    done
    printf '%s\n' "${urls[@]}"
}

# 生成 docker-compose.yml
generate_compose_file() {
    # 验证配置
    if ! validate_config_arrays "MinIO" "env_ports" "env_volumes" "env_environment"; then
        return 1
    fi
    
    # MinIO特殊配置 - 添加启动命令
    local extra_config="    command: server /data --console-address \":9090\""
    
    # 生成配置文件
    generate_docker_compose "$base_container_name" "$base_image_name" "$base_container_name" \
                           "$base_install_path" "env_ports" "env_volumes" "env_environment" "$extra_config"
}

# ============================================
# 命令实现
# ============================================

# 配置信息显示
config() {
    echo "基础配置:"
    echo "  ├─ 镜像名称: $base_image_name"
    echo "  ├─ 容器名称: $base_container_name"
    echo "  ├─ 安装路径: $base_install_path"
    echo "  └─ 服务器IP: $base_ip"
    echo
    
    echo "端口映射:"
    local port_count=${#env_ports[@]}
    for i in "${!env_ports[@]}"; do
        local prefix="  ├─"
        if [[ $((i + 1)) -eq $port_count ]]; then
            prefix="  └─"
        fi
        echo "$prefix ${env_ports[$i]}"
    done
    echo
    
    echo "卷挂载:"
    local volume_count=${#env_volumes[@]}
    for i in "${!env_volumes[@]}"; do
        local prefix="  ├─"
        if [[ $((i + 1)) -eq $volume_count ]]; then
            prefix="  └─"
        fi
        echo "$prefix ${env_volumes[$i]}"
    done
    echo
    
    echo "环境变量:"
    local env_count=${#env_environment[@]}
    for i in "${!env_environment[@]}"; do
        local prefix="  ├─"
        if [[ $((i + 1)) -eq $env_count ]]; then
            prefix="  └─"
        fi
        echo "$prefix ${env_environment[$i]}"
    done
    echo
    
    echo "认证信息: admin/admin123"
}

# 查看docker-compose.yml
yml() {
    cat "${base_install_path}/docker-compose.yml"
}

# 拉取镜像
pull() {
    log_info "开始拉取MinIO镜像..."
    
    if ! check_docker; then
        return 1
    fi
    
    check_and_pull_image "$base_image_name"
}

# 安装服务
install() {
    log_info "开始安装MinIO服务..."
    
    if ! check_docker; then
        return 1
    fi
    
    if ! check_and_pull_image "$base_image_name"; then
        return 1
    fi
    
    ensure_directory "$base_install_path"
    generate_compose_file
    
    cd "$base_install_path"
    if execute_compose "up -d" "$base_install_path"; then
        log_info "MinIO服务安装完成"
        local urls=($(get_service_urls))
        for url in "${urls[@]}"; do
            log_info "访问地址: $url"
        done
        log_info "认证信息: admin/admin123"
    else
        log_error "MinIO服务安装失败"
        return 1
    fi
}

# 卸载服务
uninstall() {
    log_info "开始卸载MinIO服务..."
    
    cd "$base_install_path" 2>/dev/null || true
    execute_compose "down" "$base_install_path"
    remove_image_safe "$base_image_name"
    
    if confirm_action "是否删除服务数据目录"; then
        remove_directory_safe "$base_install_path"
        log_info "服务数据删除完成"
    else
        log_info "保留服务数据目录: $base_install_path"
    fi
}

# 停止服务
down() {
    cd "$base_install_path"
    execute_compose "down" "$base_install_path"
}

# 启动服务
up() {
    cd "$base_install_path"
    execute_compose "up -d" "$base_install_path"
}

# 删除镜像
rmi() {
    remove_image_safe "$base_image_name"
}

# 查看日志
logs() {
    docker logs -f "$base_container_name"
}

# 显示信息
info() {
    config
    echo
    
    local status=$(get_container_status "$base_container_name")
    local status_display=$(get_status_display "$status")
    
    echo "服务状态: ${status_display}"
    
    if [[ "$status" == "running" ]]; then
        echo
        echo "访问地址:"
        local urls=($(get_service_urls))
        for url in "${urls[@]}"; do
            echo "  └─ $url"
        done
        echo
        show_container_info "$base_container_name"
    fi
}

# 显示帮助信息
help() {
    cat << EOF
服务部署脚本

用法: $0 <命令>

命令:
  config       显示配置信息
  yml          查看docker-compose.yml文件
  pull         拉取Docker镜像
  install      安装服务
  uninstall    卸载服务
  down         停止服务
  up           启动服务
  rmi          删除镜像
  logs         查看服务日志
  info         显示服务信息
  help         显示此帮助信息

示例:
  $0 install   # 安装服务
  $0 yml       # 查看docker-compose.yml配置
  $0 logs      # 查看服务日志
  $0 info      # 显示服务信息

EOF
}

# ============================================
# 主函数
# ============================================

main() {
    if [[ $# -eq 0 ]]; then
        help
        exit 1
    fi
    
    local command="$1"
    
    case "$command" in
        "config")
            config
            ;;
        "yml")
            yml
            ;;
        "pull")
            pull
            ;;
        "install")
            install
            ;;
        "uninstall")
            uninstall
            ;;
        "down")
            down
            ;;
        "up")
            up
            ;;
        "rmi")
            rmi
            ;;
        "logs")
            logs
            ;;
        "info")
            info
            ;;
        "help"|"-h"|"--help")
            help
            ;;
        *)
            log_error "未知命令: $command"
            help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
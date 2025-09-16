#!/bin/bash

# Jenkins 部署脚本 - 子脚本
# 版本: 2.0
# 描述: Jenkins CI/CD 服务部署脚本

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
base_image_name="jenkins/jenkins:lts"
base_container_name="jenkins"
base_install_path="/opt/server/jenkins"
base_ip=$(get_local_ip)

# 端口配置数组 (格式: "宿主机端口:容器端口")
declare -a env_ports=(
    "8080:8080"   # Web界面端口
    "50000:50000" # JNLP端口
)

# 卷挂载配置数组 (格式: "宿主机路径:容器路径")
declare -a env_volumes=(
    "${base_install_path}/data:/var/jenkins_home"
    "${base_install_path}/logs:/var/log/jenkins"
)

# 环境变量配置数组 (格式: "变量名=值")
declare -a env_environment=(
    "TZ :Asia/Shanghai"
)

# ============================================
# 服务信息获取
# ============================================

# 获取服务URL
get_service_urls() {
    local urls=()
    for port_mapping in "${env_ports[@]}"; do
        local host_port=$(echo "$port_mapping" | cut -d':' -f1)
        if [[ "$host_port" == "8080" ]]; then
            urls+=("http://${base_ip}:${host_port}/")
        fi
    done
    printf '%s\n' "${urls[@]}"
}

# 获取初始密码
get_initial_password() {
    local password_file="${base_install_path}/data/secrets/initialAdminPassword"
    if check_file_readable "$password_file"; then
        cat "$password_file" 2>/dev/null || echo "无法读取"
    else
        echo "密码文件不存在或无法访问"
    fi
}

# 生成 docker-compose.yml
generate_compose_file() {
    # 验证配置
    if ! validate_config_arrays "Jenkins" "env_ports" "env_volumes" "env_environment"; then
        return 1
    fi
    
    # Jenkins特殊配置
    local extra_config="    privileged: true
    user: root"
    
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
}

# 拉取镜像
pull() {
    log_info "开始拉取 Jenkins 镜像..."
    
    if ! check_docker; then
        return 1
    fi
    
    check_and_pull_image "$base_image_name"
}

# 安装服务
install() {
    log_info "开始安装 Jenkins 服务..."
    
    if ! check_docker; then
        return 1
    fi
    
    # 检查并拉取镜像
    if ! check_and_pull_image "$base_image_name"; then
        return 1
    fi
    
    # 创建目录结构
    log_info "创建 Jenkins 目录结构..."
    create_directory "${base_install_path}/data"
    create_directory "${base_install_path}/logs"
    
    # 创建 docker-compose.yml
    generate_compose_file
    
    # 启动服务
    if execute_compose "up -d" "$base_install_path"; then
        log_info "Jenkins 服务安装完成"
        
        # 显示访问信息
        local urls=($(get_service_urls))
        for url in "${urls[@]}"; do
            log_info "访问地址: $url"
        done
        
        # 等待服务启动
        log_info "等待 Jenkins 服务完全启动..."
        if wait_for_service "$base_ip" "8080" 60; then
            # 获取初始密码
            local initial_password=$(get_initial_password)
            if [[ "$initial_password" != "密码文件不存在或无法访问" ]]; then
                log_separator
                log_info "Jenkins 初始管理员密码: $initial_password"
                log_separator
                log_info "请复制上面的密码用于 Jenkins 初始化配置"
            else
                log_warn "Jenkins 初始密码暂未生成，请稍后查看"
                log_info "查看命令: cat ${base_install_path}/data/secrets/initialAdminPassword"
            fi
        else
            log_warn "Jenkins 服务启动超时，请检查服务状态"
        fi
        
        log_info "首次访问需要使用初始密码进行配置"
        return 0
    else
        log_error "Jenkins 服务部署失败"
        return 1
    fi
}

# 卸载服务 (先停止再删除镜像)
uninstall() {
    log_info "开始卸载 Jenkins 服务..."
    
    # 先执行 down 操作
    down
    
    # 再执行 rmi 操作
    rmi
    
    # 询问是否删除数据目录
    if confirm_action "是否删除 Jenkins 数据目录 ${base_install_path}"; then
        safe_remove_directory "$base_install_path" true
    else
        log_info "保留 Jenkins 数据目录"
    fi
    
    log_info "Jenkins 服务卸载完成"
}

# 停止服务
down() {
    
    if [[ ! -d "$base_install_path" ]]; then
        log_warn "Jenkins 安装目录不存在: $base_install_path"
        return 0
    fi
    
    if execute_compose "down" "$base_install_path"; then
        return 0
    else
        # 备用方案：直接停止容器
        log_warn "使用备用方案停止容器..."
        stop_and_remove_container "$base_container_name"
        return 0
    fi
}

# 启动服务
up() {
    
    if [[ ! -d "$base_install_path" ]]; then
        log_error "Jenkins 未安装，请先执行 install 命令"
        return 1
    fi
    
    if execute_compose "up -d" "$base_install_path"; then
        # 显示访问信息
        local urls=($(get_service_urls))
        for url in "${urls[@]}"; do
            log_info "Jenkins 服务启动成功，访问地址: $url"
        done
        return 0
    else
        return 1
    fi
}

# 删除镜像
rmi() {
    remove_image_safe "$base_image_name"
}

# 查看日志
logs() {
    
    if ! is_container_running "$base_container_name"; then
        log_error "Jenkins 容器未运行"
        return 1
    fi
    
    docker logs -f "$base_container_name"
}

# 查看YML命令
yml() {
    local compose_file="${base_install_path}/docker-compose.yml"
    
    log_title "Jenkins Docker Compose 配置文件"
    
    if [[ -f "$compose_file" ]]; then
        log_subtitle "文件位置: $compose_file"
        log_line
        cat "$compose_file"
        log_separator
        
        echo "文件信息:"
        echo "  ├─ 大小: $(du -h "$compose_file" | cut -f1)"
        echo "  ├─ 修改时间: $(stat -c '%y' "$compose_file" 2>/dev/null || stat -f '%Sm' "$compose_file" 2>/dev/null || echo '无法获取')"
        echo "  └─ 权限: $(ls -l "$compose_file" | awk '{print $1}')"
        
    else
        log_warn "配置文件不存在: $compose_file"
        echo "您可以使用以下命令生成配置文件:"
        echo "  ./jenkins.sh install  # 安装时会自动生成"
    fi
}

# 显示信息 - 复用config结果并添加状态和定制化内容
info() {
    local status=$(get_container_status "$base_container_name")
    local status_display=$(get_status_display "$status")
    
    log_title "Jenkins 服务完整信息"
    
    # 复用config的配置信息
    config
    echo
    
    # 单独显示状态
    echo "服务状态: $status_display"
    echo
    
    # 定制化的运行时信息
    if [[ "$status" == "running" ]]; then
        echo "运行时信息:"
        
        # 访问地址
        local urls=($(get_service_urls))
        for url in "${urls[@]}"; do
            echo "  ├─ 访问地址: $url"
        done
        
        # 初始密码
        local initial_password=$(get_initial_password)
        if [[ "$initial_password" != "密码文件不存在或无法访问" ]]; then
            echo "  ├─ 初始管理员密码: $initial_password"
        fi
        
        # 容器详细信息
        echo "  └─ 容器运行信息:"
        show_container_info "$base_container_name" | sed 's/^/      /'
        echo
        
    elif [[ "$status" == "stopped" ]]; then
        echo "提示信息:"
        echo "  └─ 服务已停止，可使用 'up' 命令启动"
        echo
        
    else
        echo "提示信息:"
        echo "  └─ 服务未安装，可使用 'install' 命令安装"
        echo
    fi
    
    # 管理提示部分
    echo "管理命令:"
    case "$status" in
        "running")
            echo "  ├─ 停止服务: ./jenkins.sh down"
            echo "  ├─ 查看日志: ./jenkins.sh logs"
            echo "  └─ 重启服务: ./jenkins.sh down && ./jenkins.sh up"
            ;;
        "stopped")
            echo "  ├─ 启动服务: ./jenkins.sh up"
            echo "  ├─ 卸载服务: ./jenkins.sh uninstall"
            echo "  └─ 查看配置: ./jenkins.sh config"
            ;;
        *)
            echo "  ├─ 安装服务: ./jenkins.sh install"
            echo "  ├─ 拉取镜像: ./jenkins.sh pull"
            echo "  └─ 查看配置: ./jenkins.sh config"
            ;;
    esac
    
    log_separator
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

# 主函数
main() {
    if [[ $# -eq 0 ]]; then
        help
        exit 1
    fi
    
    local command="$1"
    
    case "$command" in
        "config") 
            log_title "Jenkins 服务配置信息"
            config
            log_separator
            ;;
        "pull") pull ;;
        "install") install ;;
        "uninstall") uninstall ;;
        "down") down ;;
        "up") up ;;
        "rmi") rmi ;;
        "logs") logs ;;
        "yml") yml "${@:2}" ;;
        "info") info ;;
        "help"|"-h"|"--help") help ;;
        *)
            log_error "未知命令: $command"
            help
            exit 1
            ;;
    esac
}

# 如果直接执行此脚本，则调用主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
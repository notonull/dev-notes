#!/bin/bash

# Docker服务自动化部署主脚本
# 作者: Generated Script
# 日期: $(date)
# 服务器IP: 192.168.1.12

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检查Docker和Docker Compose是否安装
check_docker() {
    log_step "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    log_info "Docker环境检查通过"
}

# 创建基础目录结构
create_base_structure() {
    log_step "创建基础目录结构..."
    mkdir -p /opt/server
    log_info "基础目录结构创建完成"
}

# 获取可用的服务列表
get_available_services() {
    local services=()
    for script in docker-compose-*.sh; do
        if [ -f "$script" ] && [ "$script" != "docker-compose-script.sh" ]; then
            service_name=$(basename "$script" .sh | sed 's/docker-compose-//')
            services+=("$service_name")
        fi
    done
    echo "${services[@]}"
}

# 检查服务脚本是否存在
check_service_script() {
    local service_name=$1
    local script_file="docker-compose-${service_name}.sh"
    
    if [ ! -f "$script_file" ]; then
        log_error "服务 $service_name 的脚本文件 $script_file 不存在"
        return 1
    fi
    
    if [ ! -x "$script_file" ]; then
        log_info "设置 $script_file 为可执行"
        chmod +x "$script_file"
    fi
    
    return 0
}

# 调用服务脚本的方法
call_service_method() {
    local service_name=$1
    local method=$2
    local script_file="docker-compose-${service_name}.sh"
    
    if ! check_service_script "$service_name"; then
        return 1
    fi
    
    log_info "调用 $service_name 服务的 $method 方法"
    source "$script_file"
    
    # 检查方法是否存在
    if declare -f "$method" > /dev/null; then
        $method
    else
        log_error "服务 $service_name 中不存在方法 $method"
        return 1
    fi
}

# 安装所有服务
install_all() {
    log_step "开始安装所有Docker服务..."
    
    # 检查环境
    check_root
    check_docker
    create_base_structure
    
    # 记录开始时间
    start_time=$(date +%s)
    
    # 获取所有可用服务
    local services=($(get_available_services))
    
    if [ ${#services[@]} -eq 0 ]; then
        log_error "没有找到任何服务脚本"
        return 1
    fi
    
    log_info "找到以下服务: ${services[*]}"
    
    # 定义安装顺序（基础服务优先）
    local ordered_services=("mysql" "mongodb" "redis" "jenkins" "minio" "nexus" "nacos" "yapi")
    local installed_services=()
    
    # 按顺序安装服务
    for service in "${ordered_services[@]}"; do
        if [[ " ${services[*]} " =~ " ${service} " ]]; then
            log_info "=== 安装 $service 服务 ==="
            if call_service_method "$service" "install"; then
                installed_services+=("$service")
                sleep 5
            else
                log_error "$service 服务安装失败"
            fi
        fi
    done
    
    # 安装其他未在顺序中的服务
    for service in "${services[@]}"; do
        if [[ ! " ${ordered_services[*]} " =~ " ${service} " ]]; then
            log_info "=== 安装 $service 服务 ==="
            if call_service_method "$service" "install"; then
                installed_services+=("$service")
                sleep 5
            else
                log_error "$service 服务安装失败"
            fi
        fi
    done
    
    # 计算总用时
    end_time=$(date +%s)
    total_time=$((end_time - start_time))
    
    log_info "=== 安装完成 ==="
    log_info "成功安装的服务: ${installed_services[*]}"
    log_info "总用时: ${total_time}秒"
    
    # 显示服务状态
    show_services_status
}

# 显示所有服务状态
show_services_status() {
    log_step "显示所有服务状态..."
    
    echo ""
    echo "=================================================="
    echo "              服务部署状态总览"
    echo "=================================================="
    
    local services=($(get_available_services))
    
    for service in "${services[@]}"; do
        if docker ps | grep -q "$service"; then
            local port=$(docker port "$service" 2>/dev/null | head -1 | cut -d':' -f2)
            if [ -n "$port" ]; then
                echo -e "${GREEN}✓${NC} $service - 运行中 - http://192.168.1.12:$port/"
            else
                echo -e "${GREEN}✓${NC} $service - 运行中"
            fi
        else
            echo -e "${RED}✗${NC} $service - 未运行"
        fi
    done
    
    echo "=================================================="
    echo ""
    
    log_info "可以使用以下命令检查各服务日志:"
    for service in "${services[@]}"; do
        echo "docker logs $service"
    done
}

# 启动所有服务
up_all() {
    log_step "启动所有Docker服务..."
    
    local services=($(get_available_services))
    
    for service in "${services[@]}"; do
        if [ -d "/opt/server/$service" ] && [ -f "/opt/server/$service/docker-compose.yml" ]; then
            log_info "启动服务: $service"
            cd "/opt/server/$service"
            docker compose up -d
            sleep 3
        fi
    done
    
    log_info "所有服务已启动"
    show_services_status
}

# 停止所有服务
down_all() {
    log_step "停止所有Docker服务..."
    
    local services=($(get_available_services))
    
    for service in "${services[@]}"; do
        if [ -d "/opt/server/$service" ] && [ -f "/opt/server/$service/docker-compose.yml" ]; then
            log_info "停止服务: $service"
            cd "/opt/server/$service"
            docker compose down
        fi
    done
    
    log_info "所有服务已停止"
}

# 启动单个服务
up_service() {
    local service_name=$1
    log_step "启动${service_name}服务..."
    
    if [ -d "/opt/server/$service_name" ] && [ -f "/opt/server/$service_name/docker-compose.yml" ]; then
        cd "/opt/server/$service_name"
        docker compose up -d
        log_info "${service_name}服务启动完成"
    else
        log_error "${service_name}服务未安装或配置文件缺失"
        return 1
    fi
}

# 停止单个服务
down_service() {
    local service_name=$1
    log_step "停止${service_name}服务..."
    
    if [ -d "/opt/server/$service_name" ] && [ -f "/opt/server/$service_name/docker-compose.yml" ]; then
        cd "/opt/server/$service_name"
        docker compose down
        log_info "${service_name}服务停止完成"
    else
        log_error "${service_name}服务未安装或配置文件缺失"
        return 1
    fi
}

# 查看单个服务日志
logs_service() {
    local service_name=$1
    log_step "查看${service_name}服务日志..."
    
    if [ -d "/opt/server/$service_name" ] && [ -f "/opt/server/$service_name/docker-compose.yml" ]; then
        cd "/opt/server/$service_name"
        docker compose logs -f
    else
        log_error "${service_name}服务未安装或配置文件缺失"
        return 1
    fi
}

# 卸载所有服务（危险操作）
uninstall_all() {
    log_warn "这将删除所有服务及其数据，此操作不可逆！"
    read -p "确认删除所有服务和数据？(yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        log_step "卸载所有Docker服务和数据..."
        
        # 停止所有服务
        down_all
        
        # 获取所有服务名
        local services=($(get_available_services))
        
        # 删除所有容器
        for service in "${services[@]}"; do
            docker rm -f "$service" 2>/dev/null || true
        done
        
        # 删除数据目录
        rm -rf /opt/server
        
        log_info "所有服务和数据已卸载完成"
    else
        log_info "操作已取消"
    fi
}

# 卸载单个服务
uninstall_service() {
    local service_name=$1
    log_warn "这将删除${service_name}服务及其数据，此操作不可逆！"
    read -p "确认删除${service_name}服务和数据？(yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        log_step "卸载${service_name}服务..."
        
        # 停止服务
        down_service "$service_name"
        
        # 删除容器
        docker rm -f "$service_name" 2>/dev/null || true
        
        # 删除数据目录
        if [ -d "/opt/server/$service_name" ]; then
            rm -rf "/opt/server/$service_name"
            log_info "${service_name}服务和数据已卸载完成"
        else
            log_warn "${service_name}服务目录不存在"
        fi
    else
        log_info "操作已取消"
    fi
}

# Docker状态相关命令
docker_status() {
    local service_name=$1
    
    if [ -z "$service_name" ]; then
        # 显示所有Docker服务状态
        show_services_status
    else
        # 显示指定服务状态
        if docker ps | grep -q "$service_name"; then
            echo -e "${GREEN}✓${NC} $service_name - 运行中"
            docker ps --filter "name=$service_name"
        else
            echo -e "${RED}✗${NC} $service_name - 未运行"
        fi
    fi
}

# 帮助信息
show_help() {
    echo ""
    echo "Docker服务自动化管理脚本 - 模块化版本"
    echo ""
    echo "用法: $0 [命令] [服务名]"
    echo ""
    echo "服务管理命令:"
    echo "  install              安装所有服务"
    echo "  install [服务名]      安装指定服务"
    echo "  up                   启动所有服务"
    echo "  up [服务名]          启动指定服务"
    echo "  down                 停止所有服务"
    echo "  down [服务名]        停止指定服务"
    echo "  logs [服务名]        查看指定服务日志"
    echo "  uninstall            卸载所有服务（危险操作）"
    echo "  uninstall [服务名]   卸载指定服务（危险操作）"
    echo "  status               显示所有服务状态"
    echo "  help                 显示此帮助信息"
    echo ""
    echo "Docker状态命令:"
    echo "  docker status        显示所有Docker服务状态"
    echo "  docker status [服务名] 显示指定服务状态"
    echo ""
    echo "可用服务: $(get_available_services)"
    echo ""
    echo "示例:"
    echo "  $0 install           # 安装所有服务"
    echo "  $0 install jenkins   # 仅安装Jenkins"
    echo "  $0 up                # 启动所有服务"
    echo "  $0 up jenkins        # 启动Jenkins服务"
    echo "  $0 down jenkins      # 停止Jenkins服务"
    echo "  $0 logs jenkins      # 查看Jenkins服务日志"
    echo "  $0 docker status     # 查看所有服务状态"
    echo "  $0 docker status jenkins # 查看Jenkins状态"
    echo "  $0 uninstall jenkins # 卸载Jenkins服务"
    echo ""
    echo "注意: 服务脚本文件格式为 docker-compose-[服务名].sh"
    echo ""
}

# 主函数
main() {
    local command=$1
    local service=$2
    
    case "$command" in
        "install")
            if [ -z "$service" ]; then
                install_all
            else
                check_root && check_docker && create_base_structure && call_service_method "$service" "install"
            fi
            ;;
        "up")
            if [ -z "$service" ]; then
                up_all
            else
                up_service "$service"
            fi
            ;;
        "down")
            if [ -z "$service" ]; then
                down_all
            else
                down_service "$service"
            fi
            ;;
        "logs")
            if [ -z "$service" ]; then
                log_error "请指定要查看日志的服务名"
                show_help
                exit 1
            else
                logs_service "$service"
            fi
            ;;
        "uninstall")
            if [ -z "$service" ]; then
                uninstall_all
            else
                uninstall_service "$service"
            fi
            ;;
        "status")
            show_services_status
            ;;
        "docker")
            case "$service" in
                "status")
                    docker_status "$3"
                    ;;
                *)
                    log_error "无效的docker命令: $service"
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "无效的命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 如果没有参数，显示帮助
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# 执行主函数
main "$@"
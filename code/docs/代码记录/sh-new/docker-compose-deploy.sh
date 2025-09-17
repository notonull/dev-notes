#!/bin/bash

# Docker Compose 部署脚本 - 主脚本
# 版本: 2.0
# 描述: 统一管理多个Docker服务的部署脚本

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 发布目录
DEPLOY_DIR="${SCRIPT_DIR}/deploy"
# 工具包目录
LIB_DIR="${SCRIPT_DIR}/lib"

# 加载公共库
source "${LIB_DIR}/logger.sh"
source "${LIB_DIR}/system_utils.sh"

# 注册脚本列表
declare -A REGISTERED_SCRIPTS
REGISTERED_SCRIPTS["jenkins"]="deploy/jenkins.sh"
REGISTERED_SCRIPTS["mysql"]="deploy/mysql.sh"
REGISTERED_SCRIPTS["redis"]="deploy/redis.sh"
REGISTERED_SCRIPTS["mongodb"]="deploy/mongodb.sh"
REGISTERED_SCRIPTS["minio"]="deploy/minio.sh"
REGISTERED_SCRIPTS["nacos"]="deploy/nacos.sh"

# 安装顺序列表 - 从注册脚本列表中选择需要操作的服务
declare -a INSTALL_ORDER=(
    "mysql"     
    "redis"     
    "mongodb"   
    "jenkins"   
    "minio"     
    "nacos"     
)

# 获取所有可用服务代码列表
list() {
    echo "${INSTALL_ORDER[@]}"
}

# 获取指定服务代码的脚本路径
get() {
    local code="$1"
    local registered_path="${REGISTERED_SCRIPTS[$code]}"
    
    # 如果是绝对路径，直接返回
    if [[ "$registered_path" = /* ]]; then
        echo "$registered_path"
    else
        # 相对路径，基于SCRIPT_DIR解析
        echo "${SCRIPT_DIR}/${registered_path}"
    fi
}

# 检查脚本是否存在
check() {
    local code="$1"
    local script_path="$(get "$code")"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "脚本不存在: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        chmod +x "$script_path" 2>/dev/null || true
    fi
    
    return 0
}

# 执行子脚本命令
execute() {
    local code="$1"
    local command="$2"
    
    if [[ ! -v REGISTERED_SCRIPTS[$code] ]]; then
        log_error "未注册的脚本代码: $code"
        log_info "可用的脚本代码: $(list)"
        return 1
    fi
    
    if ! check "$code"; then
        return 1
    fi
    
    local script_path="$(get "$code")"
    log_info "执行 $code 的 $command 操作..."
    
    # 导出路径供子脚本使用
    export SCRIPT_DIR="${SCRIPT_DIR}"
    export LIB_DIR="${LIB_DIR}"
    
    # 传递额外参数给子脚本
    local script_args=("$@")
    bash "$script_path" "$command" "${script_args[@]:2}"
}

# 执行所有脚本的命令（需要确认）
execute_all() {
    local command="$1"
    local codes=($(list))
    
    if [[ ${#codes[@]} -eq 0 ]]; then
        log_warn "没有注册的脚本"
        return 0
    fi
    
    log_warn "即将对所有服务执行 '$command' 操作:"
    for code in "${codes[@]}"; do
        echo "  - $code"
    done
    
    if ! confirm_action "确认执行"; then
        log_info "操作已取消"
        return 0
    fi
    
    local success_count=0
    local total_count=${#codes[@]}
    
    for code in "${codes[@]}"; do
        log_info "执行 $code 的 $command 操作..."
        if execute "$code" "$command"; then
            ((success_count++))
            log_info "$code 的 $command 操作成功"
        else
            log_error "$code 的 $command 操作失败"
        fi
        echo "----------------------------------------"
    done
    
    log_info "批量操作完成: $success_count/$total_count 成功"
}


# 显示帮助信息
help() {
    cat << EOF
Docker Compose 部署脚本

用法: $0 <命令> [服务代码]

命令:
  list                 查询所有注册的脚本
  get [<code>]         定位脚本路径 (显示所有或指定脚本的绝对路径)
  config [<code>]      显示配置信息
  yml <code>          查看docker-compose.yml (必须指定服务代码)
  pull [<code>]        拉取Docker镜像 (需要确认)
  install [<code>]     安装服务 (需要确认)
  uninstall [<code>]   卸载服务 (需要确认)
  down [<code>]        停止服务 (需要确认)
  up [<code>]          启动服务 (需要确认)
  rmi [<code>]         删除镜像 (需要确认)
  logs <code>          查看服务日志 (必须指定服务代码)
  info [<code>]        显示服务信息
  help                 显示此帮助信息

可用的服务代码 (按推荐执行顺序):
$(for code in $(list); do echo "  $code"; done)

示例:
  $0 install jenkins    # 安装Jenkins服务
  $0 install           # 安装所有服务 (需要确认)
  $0 yml jenkins       # 查看Jenkins的docker-compose.yml
  $0 logs jenkins      # 查看Jenkins服务日志
  $0 info              # 显示所有服务信息

EOF
}

# 主函数
main() {
    if [[ $# -eq 0 ]]; then
        help
        exit 1
    fi
    
    local command="$1"
    local code="${2:-}"
    
    case "$command" in
        "list")
            log_info "注册的脚本列表:"
            for code in $(list); do
                echo "  $code -> ${REGISTERED_SCRIPTS[$code]}"
            done
            ;;
        "get")
            if [[ -n "$code" ]]; then
                if [[ ! -v REGISTERED_SCRIPTS[$code] ]]; then
                    log_error "未注册的脚本代码: $code"
                    log_info "可用的脚本代码: $(list)"
                    exit 1
                fi
                script_path="$(get "$code")"
                log_info "$code -> $script_path"
                if [[ -f "$script_path" ]]; then
                    log_info "状态: 存在"
                else
                    log_warn "状态: 不存在"
                fi
            else
                log_info "所有脚本的绝对路径:"
                for code in $(list); do
                    script_path="$(get "$code")"
                    status="存在"
                    if [[ ! -f "$script_path" ]]; then
                        status="不存在"
                    fi
                    echo "  $code -> $script_path [$status]"
                done
            fi
            ;;
        "config")
            if [[ -n "$code" ]]; then
                execute "$code" "config" "${@:3}"
            else
                for code in $(list); do
                    execute "$code" "config"
                done
            fi
            ;;
        "yml")
            if [[ -z "$code" ]]; then
                log_error "yml 命令必须指定服务代码"
                log_info "可用的服务代码: $(list)"
                exit 1
            fi
            execute "$code" "yml" "${@:3}"
            ;;
        "pull")
            if [[ -n "$code" ]]; then
                execute "$code" "pull" "${@:3}"
            else
                execute_all "pull"
            fi
            ;;
        "install")
            if [[ -n "$code" ]]; then
                execute "$code" "install" "${@:3}"
            else
                execute_all "install"
            fi
            ;;
        "uninstall")
            if [[ -n "$code" ]]; then
                execute "$code" "uninstall" "${@:3}"
            else
                execute_all "uninstall"
            fi
            ;;
        "down")
            if [[ -n "$code" ]]; then
                execute "$code" "down" "${@:3}"
            else
                execute_all "down"
            fi
            ;;
        "up")
            if [[ -n "$code" ]]; then
                execute "$code" "up" "${@:3}"
            else
                execute_all "up"
            fi
            ;;
        "rmi")
            if [[ -n "$code" ]]; then
                execute "$code" "rmi" "${@:3}"
            else
                execute_all "rmi"
            fi
            ;;
        "logs")
            if [[ -z "$code" ]]; then
                log_error "logs 命令必须指定服务代码"
                log_info "可用的服务代码: $(list)"
                exit 1
            fi
            execute "$code" "logs" "${@:3}"
            ;;
        "info")
            if [[ -n "$code" ]]; then
                execute "$code" "info" "${@:3}"
            else
                for code in $(list); do
                    execute "$code" "info"
                done
            fi
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
#!/bin/bash

# Docker Compose 部署脚本 - 主脚本
# 版本: 2.0
# 描述: 统一管理多个Docker服务的部署脚本

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 确保SCRIPT_DIR指向正确的根目录
while [[ ! -f "$SCRIPT_DIR/docker-compose-deploy.sh" && "$(basename "$SCRIPT_DIR")" == "lib" ]]; do
    SCRIPT_DIR="$(dirname "$SCRIPT_DIR")"
done

DEPLOY_DIR="${SCRIPT_DIR}/deploy"
LIB_DIR="${SCRIPT_DIR}/lib"

# 加载公共库
source "${LIB_DIR}/logger.sh"
source "${LIB_DIR}/system_utils.sh"

# 注册的子脚本映射
declare -A REGISTERED_SCRIPTS
REGISTERED_SCRIPTS["jenkins"]="deploy/jenkins.sh"
REGISTERED_SCRIPTS["mysql"]="deploy/mysql.sh"
REGISTERED_SCRIPTS["redis"]="deploy/redis.sh"
REGISTERED_SCRIPTS["mongodb"]="deploy/mongodb.sh"
REGISTERED_SCRIPTS["minio"]="deploy/minio.sh"
REGISTERED_SCRIPTS["nacos"]="deploy/nacos.sh"

# 注册顺序数组 (按执行顺序排列)
declare -a SCRIPT_ORDER=(
    "mysql"      # 1. 先启动数据库服务
    "redis"      # 2. 缓存服务
    "mongodb"    # 3. 文档数据库
    "jenkins"    # 4. CI/CD服务
    "minio"      # 5. 对象存储
    "nacos"      # 6. 配置中心 (依赖MySQL)
)

# 获取所有注册的脚本代码 (按注册顺序)
get_all_codes() {
    echo "${SCRIPT_ORDER[@]}"
}

# 获取脚本绝对路径
get_script_path() {
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
check_script_exists() {
    local code="$1"
    local script_path="$(get_script_path "$code")"
    
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
execute_script() {
    local code="$1"
    local command="$2"
    
    if [[ ! -v REGISTERED_SCRIPTS[$code] ]]; then
        log_error "未注册的脚本代码: $code"
        log_info "可用的脚本代码: $(get_all_codes)"
        return 1
    fi
    
    if ! check_script_exists "$code"; then
        return 1
    fi
    
    local script_path="$(get_script_path "$code")"
    log_info "执行 $code 的 $command 操作..."
    
    # 导出路径供子脚本使用
    export SCRIPT_DIR="${SCRIPT_DIR}"
    export LIB_DIR="${LIB_DIR}"
    
    # 传递额外参数给子脚本
    local script_args=("$@")
    bash "$script_path" "$command" "${script_args[@]:2}"
}

# 执行所有脚本的命令（需要确认的操作）
execute_all_with_confirmation() {
    local command="$1"
    local codes=($(get_all_codes))
    
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
        if execute_script "$code" "$command"; then
            ((success_count++))
            log_info "$code 的 $command 操作成功"
        else
            log_error "$code 的 $command 操作失败"
        fi
        echo "----------------------------------------"
    done
    
    log_info "批量操作完成: $success_count/$total_count 成功"
}

# 执行所有脚本的命令（不需要确认的操作）
execute_all_without_confirmation() {
    local command="$1"
    local codes=($(get_all_codes))
    
    if [[ ${#codes[@]} -eq 0 ]]; then
        log_warn "没有注册的脚本"
        return 0
    fi
    
    for code in "${codes[@]}"; do
        log_info "执行 $code 的 $command 操作..."
        execute_script "$code" "$command"
        echo "----------------------------------------"
    done
}

# 显示帮助信息
show_help() {
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
$(for code in $(get_all_codes); do echo "  $code"; done)

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
        show_help
        exit 1
    fi
    
    local command="$1"
    local code="${2:-}"
    
    case "$command" in
        "list")
            log_info "注册的脚本列表:"
            for code in $(get_all_codes); do
                echo "  $code -> ${REGISTERED_SCRIPTS[$code]}"
            done
            ;;
        "get")
            if [[ -n "$code" ]]; then
                if [[ ! -v REGISTERED_SCRIPTS[$code] ]]; then
                    log_error "未注册的脚本代码: $code"
                    log_info "可用的脚本代码: $(get_all_codes)"
                    exit 1
                fi
                script_path="$(get_script_path "$code")"
                log_info "$code -> $script_path"
                if [[ -f "$script_path" ]]; then
                    log_info "状态: 存在"
                else
                    log_warn "状态: 不存在"
                fi
            else
                log_info "所有脚本的绝对路径:"
                for code in $(get_all_codes); do
                    script_path="$(get_script_path "$code")"
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
                execute_script "$code" "config" "${@:3}"
            else
                execute_all_without_confirmation "config"
            fi
            ;;
        "yml")
            if [[ -z "$code" ]]; then
                log_error "yml 命令必须指定服务代码"
                log_info "可用的服务代码: $(get_all_codes)"
                exit 1
            fi
            execute_script "$code" "yml" "${@:3}"
            ;;
        "pull")
            if [[ -n "$code" ]]; then
                execute_script "$code" "pull" "${@:3}"
            else
                execute_all_with_confirmation "pull"
            fi
            ;;
        "install")
            if [[ -n "$code" ]]; then
                execute_script "$code" "install" "${@:3}"
            else
                execute_all_with_confirmation "install"
            fi
            ;;
        "uninstall")
            if [[ -n "$code" ]]; then
                execute_script "$code" "uninstall" "${@:3}"
            else
                execute_all_with_confirmation "uninstall"
            fi
            ;;
        "down")
            if [[ -n "$code" ]]; then
                execute_script "$code" "down" "${@:3}"
            else
                execute_all_with_confirmation "down"
            fi
            ;;
        "up")
            if [[ -n "$code" ]]; then
                execute_script "$code" "up" "${@:3}"
            else
                execute_all_with_confirmation "up"
            fi
            ;;
        "rmi")
            if [[ -n "$code" ]]; then
                execute_script "$code" "rmi" "${@:3}"
            else
                execute_all_with_confirmation "rmi"
            fi
            ;;
        "logs")
            if [[ -z "$code" ]]; then
                log_error "logs 命令必须指定服务代码"
                log_info "可用的服务代码: $(get_all_codes)"
                exit 1
            fi
            execute_script "$code" "logs" "${@:3}"
            ;;
        "info")
            if [[ -n "$code" ]]; then
                execute_script "$code" "info" "${@:3}"
            else
                execute_all_without_confirmation "info"
            fi
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
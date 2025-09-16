#!/bin/bash

# 系统工具�?
# 版本: 1.0
# 描述: 提供系统相关的通用功能

# 加载日志�?
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
source "${SCRIPT_DIR}/lib/logger.sh"

# 获取本机IP地址
get_local_ip() {
    local ip=""
    
    # 尝试多种方法获取IP
    if command -v hostname &> /dev/null; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    if [[ -z "$ip" ]] && command -v ip &> /dev/null; then
        ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
    fi
    
    if [[ -z "$ip" ]] && command -v ifconfig &> /dev/null; then
        ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
    fi
    
    # 默认回退
    if [[ -z "$ip" ]]; then
        ip="127.0.0.1"
    fi
    
    echo "$ip"
}

# 检查端口是否被占用
check_port_in_use() {
    local port="$1"
    
    if command -v netstat &> /dev/null; then
        netstat -tlnp 2>/dev/null | grep -q ":${port} "
    elif command -v ss &> /dev/null; then
        ss -tlnp 2>/dev/null | grep -q ":${port} "
    else
        # 使用lsof作为备�?
        if command -v lsof &> /dev/null; then
            lsof -i ":${port}" &> /dev/null
        else
            return 1
        fi
    fi
}

# 创建目录（带权限检查）
create_directory() {
    local dir_path="$1"
    local owner="${2:-}"
    
    if [[ -d "$dir_path" ]]; then
        log_debug "目录已存�? $dir_path"
        return 0
    fi
    
    log_info "创建目录: $dir_path"
    
    if mkdir -p "$dir_path"; then
        log_info "目录创建成功: $dir_path"
        
        # 设置所有�?
        if [[ -n "$owner" ]]; then
            chown "$owner" "$dir_path" 2>/dev/null || log_warn "无法设置目录所有�? $dir_path"
        fi
        
        return 0
    else
        log_error "目录创建失败: $dir_path"
        return 1
    fi
}

# 检查文件是否存在并可读
check_file_readable() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        return 1
    fi
    
    if [[ ! -r "$file_path" ]]; then
        return 1
    fi
    
    return 0
}

# 安全删除目录（带确认�?
safe_remove_directory() {
    local dir_path="$1"
    local force="${2:-false}"
    
    if [[ ! -d "$dir_path" ]]; then
        log_debug "目录不存在，跳过删除: $dir_path"
        return 0
    fi
    
    if [[ "$force" != "true" ]]; then
        echo -n "确认删除目录 ${dir_path}? (y/N): "
        read -r confirmation
        
        if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
            log_info "取消删除目录: $dir_path"
            return 0
        fi
    fi
    
    log_info "删除目录: $dir_path"
    if rm -rf "$dir_path"; then
        log_info "目录删除成功: $dir_path"
        return 0
    else
        log_error "目录删除失败: $dir_path"
        return 1
    fi
}

# 等待服务启动
wait_for_service() {
    local host="$1"
    local port="$2"
    local timeout="${3:-60}"
    local interval="${4:-5}"
    
    log_info "等待服务启动 ${host}:${port} (超时: ${timeout}�?"
    
    local count=0
    while [[ $count -lt $timeout ]]; do
        if command -v nc &> /dev/null; then
            if nc -z "$host" "$port" 2>/dev/null; then
                log_success "服务已启�? ${host}:${port}"
                return 0
            fi
        elif command -v telnet &> /dev/null; then
            if timeout 1 telnet "$host" "$port" 2>/dev/null | grep -q "Connected"; then
                log_success "服务已启�? ${host}:${port}"
                return 0
            fi
        else
            # 简单的curl检�?
            if command -v curl &> /dev/null; then
                if curl -s --connect-timeout 1 "$host:$port" &>/dev/null; then
                    log_success "服务已启�? ${host}:${port}"
                    return 0
                fi
            fi
        fi
        
        sleep "$interval"
        count=$((count + interval))
        log_debug "等待服务启动... (${count}/${timeout}�?"
    done
    
    log_warn "服务启动超时: ${host}:${port}"
    return 1
}

# 确认操作
confirm_action() {
    local message="$1"
    local default="${2:-N}"
    
    local prompt="$message"
    if [[ "$default" == "Y" || "$default" == "y" ]]; then
        prompt="${prompt} (Y/n): "
    else
        prompt="${prompt} (y/N): "
    fi
    
    echo -n "$prompt"
    read -r response
    
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    if [[ "$response" == "Y" || "$response" == "y" ]]; then
        return 0
    else
        return 1
    fi
}

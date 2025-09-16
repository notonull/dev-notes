#!/bin/bash

# 调试路径问题的临时脚本

echo "=== 调试信息 ==="
echo "当前工作目录: $(pwd)"
echo "脚本所在目录: $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "SCRIPT_DIR: $SCRIPT_DIR"

echo ""
echo "=== 目录内容 ==="
echo "根目录内容:"
ls -la "$SCRIPT_DIR"

echo ""
echo "deploy目录内容:"
ls -la "$SCRIPT_DIR/deploy" 2>/dev/null || echo "deploy目录不存在"

echo ""
echo "lib目录内容:"
ls -la "$SCRIPT_DIR/lib" 2>/dev/null || echo "lib目录不存在"

echo ""
echo "=== 注册脚本检查 ==="
declare -A REGISTERED_SCRIPTS
REGISTERED_SCRIPTS["jenkins"]="deploy/jenkins.sh"

for code in "${!REGISTERED_SCRIPTS[@]}"; do
    script_path="${SCRIPT_DIR}/${REGISTERED_SCRIPTS[$code]}"
    echo "代码: $code"
    echo "路径: $script_path"
    echo "存在: $(test -f "$script_path" && echo "是" || echo "否")"
    echo "可执行: $(test -x "$script_path" && echo "是" || echo "否")"
    echo "---"
done
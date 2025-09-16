#!/bin/bash

# 演示脚本 - 展示新的模块化架构如何工作
echo "=== Docker Compose 模块化脚本架构演示 ==="
echo ""

echo "1. 脚本文件结构："
echo "   主脚本: docker-compose-script.sh"
echo "   服务脚本:"
ls -la docker-compose-*.sh | grep -v script

echo ""
echo "2. 使用示例："
echo ""

echo "安装所有服务："
echo "   ./docker-compose-script.sh install"
echo ""

echo "安装单个服务："
echo "   ./docker-compose-script.sh install jenkins"
echo "   ./docker-compose-script.sh install mysql"
echo ""

echo "启动/停止服务："
echo "   ./docker-compose-script.sh up jenkins"
echo "   ./docker-compose-script.sh down jenkins"
echo ""

echo "查看状态："
echo "   ./docker-compose-script.sh status"
echo "   ./docker-compose-script.sh docker status"
echo "   ./docker-compose-script.sh docker status jenkins"
echo ""

echo "查看日志："
echo "   ./docker-compose-script.sh logs jenkins"
echo ""

echo "3. 架构特点："
echo "   ✓ 模块化设计，每个服务独立脚本"
echo "   ✓ 主脚本负责协调和通用功能"
echo "   ✓ 支持单独安装/管理服务"
echo "   ✓ 自动发现可用服务脚本"
echo "   ✓ 统一的日志和状态管理"
echo ""

echo "4. 服务脚本标准结构："
echo "   - install() 函数：安装服务"
echo "   - check_and_pull_image() 函数：镜像管理"
echo "   - get_image() 函数：返回镜像名"
echo ""

echo "演示完成！"
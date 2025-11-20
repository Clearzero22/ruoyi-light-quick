#!/bin/bash

# RuoYi Project One-Click Startup Script for Linux/macOS
# Author: RuoYi Project Team
# Version: 1.0.0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")/.."

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_cyan() {
    echo -e "${CYAN}$1${NC}"
}

separator() {
    echo -e "\n${CYAN}============================================================${NC}\n"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 等待服务启动
wait_for_service() {
    local service_name="$1"
    local timeout="${2:-60}"
    local test_command="$3"

    log_info "等待 $service_name 服务启动..."
    local start_time=$(date +%s)
    local timeout_time=$((start_time + timeout))

    while [ $(date +%s) -lt $timeout_time ]; do
        if eval "$test_command" >/dev/null 2>&1; then
            log_success "✓ $service_name 服务已就绪"
            return 0
        fi

        local elapsed=$(($(date +%s) - start_time))
        echo -ne "\r等待中... 已等待 ${elapsed} 秒"
        sleep 2
    done

    echo
    log_error "✗ $service_name 服务启动超时"
    return 1
}

# 检查系统环境
check_environment() {
    log_info "正在检查系统环境..."

    local env_checks=(
        "Java:java:java -version"
        "Node.js:node:node -v"
        "Maven:mvn:mvn -v"
    )

    for check in "${env_checks[@]}"; do
        IFS=':' read -r name cmd version_cmd <<< "$check"
        if command_exists "$cmd"; then
            local version=$(eval "$version_cmd" 2>&1 | head -n1)
            log_success "✓ $name: $version"
        else
            log_error "✗ $name: 未安装或未配置到 PATH"
            log_warning "请先安装 $name 并确保其在系统 PATH 中"
            exit 1
        fi
    done
}

# 启动 Docker 服务
start_docker_services() {
    log_info "正在启动 Docker 服务..."

    # 检查 Docker 是否安装
    if ! command_exists docker; then
        log_error "Docker 未安装"
        log_warning "请先安装 Docker: https://docs.docker.com/get-docker/"
        return 1
    fi

    # 检查 Docker 是否运行
    if ! docker info >/dev/null 2>&1; then
        log_warning "Docker 服务未运行，正在尝试启动..."

        # 尝试启动 Docker 服务（Linux）
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command_exists systemctl; then
                sudo systemctl start docker
                sudo systemctl enable docker
            elif command_exists service; then
                sudo service docker start
            else
                log_error "无法启动 Docker 服务，请手动启动"
                return 1
            fi
        # 尝试启动 Docker Desktop（macOS）
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            open -a Docker
            log_warning "请等待 Docker Desktop 启动完成后重新运行此脚本"
            return 1
        fi

        # 等待 Docker 启动
        sleep 5
        if ! docker info >/dev/null 2>&1; then
            log_error "Docker 启动失败"
            return 1
        fi
    fi

    log_success "✓ Docker 服务正常"

    # 启动 MySQL
    log_info "正在启动 MySQL..."
    cd "$PROJECT_ROOT/mysql-env"
    docker-compose up -d

    if [ $? -eq 0 ]; then
        log_success "✓ MySQL 容器启动成功"
    else
        log_error "✗ MySQL 容器启动失败"
        return 1
    fi

    # 启动 Redis
    log_info "正在启动 Redis..."
    cd "$PROJECT_ROOT/redis-dev"
    docker-compose up -d

    if [ $? -eq 0 ]; then
        log_success "✓ Redis 容器启动成功"
    else
        log_error "✗ Redis 容器启动失败"
        return 1
    fi

    # 等待数据库服务就绪
    if ! wait_for_service "MySQL" 60 "docker exec dev-mysql-8.0-ruoyi-vue3 mysqladmin ping -h localhost -u root -p123456 2>/dev/null | grep -q 'mysqld is alive'"; then
        return 1
    fi

    if ! wait_for_service "Redis" 30 "docker exec dev-redis-7-ruoyi-vue3 redis-cli -a 123456 ping 2>/dev/null | grep -q 'PONG'"; then
        return 1
    fi

    return 0
}

# 启动后端服务
start_backend() {
    log_info "正在启动后端服务..."

    cd "$PROJECT_ROOT"

    # 检查是否需要编译
    if [ ! -d "ruoyi-admin/target/classes" ]; then
        log_info "正在编译项目..."
        mvn clean compile -DskipTests
        if [ $? -ne 0 ]; then
            log_error "✗ 项目编译失败"
            return 1
        fi
        log_success "✓ 项目编译成功"
    fi

    # 启动后端服务（后台运行）
    log_info "正在启动 Spring Boot 应用..."
    cd ruoyi-admin
    nohup mvn spring-boot:run > ../logs/backend.log 2>&1 &
    local backend_pid=$!
    echo $backend_pid > ../logs/backend.pid

    # 等待后端启动
    log_info "等待后端服务启动..."
    for i in {1..60}; do
        if curl -s http://localhost:8080 >/dev/null 2>&1; then
            log_success "✓ 后端服务启动成功 (http://localhost:8080)"
            echo $backend_pid
            return 0
        fi
        echo -ne "\r等待中... 已等待 $i 秒"
        sleep 2
    done

    echo
    log_error "✗ 后端服务启动超时"
    kill $backend_pid 2>/dev/null
    return 1
}

# 启动前端服务
start_frontend() {
    log_info "正在启动前端服务..."

    cd "$PROJECT_ROOT/ruoyi-ui"

    # 检查 node_modules 是否存在
    if [ ! -d "node_modules" ]; then
        log_info "正在安装前端依赖..."
        npm install
        if [ $? -ne 0 ]; then
            log_error "✗ 前端依赖安装失败"
            return 1
        fi
        log_success "✓ 前端依赖安装成功"
    fi

    # 启动前端服务（后台运行）
    log_info "正在启动 Vue 开发服务器..."
    nohup npm run dev > ../logs/frontend.log 2>&1 &
    local frontend_pid=$!
    echo $frontend_pid > ../logs/frontend.pid

    # 等待前端启动
    log_info "等待前端服务启动..."
    for i in {1..60}; do
        if curl -s http://localhost:80 >/dev/null 2>&1; then
            log_success "✓ 前端服务启动成功 (http://localhost:80)"
            echo $frontend_pid
            return 0
        fi
        echo -ne "\r等待中... 已等待 $i 秒"
        sleep 2
    done

    echo
    log_error "✗ 前端服务启动超时"
    kill $frontend_pid 2>/dev/null
    return 1
}

# 显示服务状态
show_service_status() {
    separator
    log_cyan "🎉 RuoYi 项目启动完成！"
    separator
    log_cyan "服务访问地址："
    echo -e "• ${BLUE}前端界面:${NC} http://localhost:80"
    echo -e "• ${BLUE}后端API:${NC}   http://localhost:8080"
    echo -e "• ${BLUE}API文档:${NC}   http://localhost:8080/swagger-ui/"
    echo -e "• ${BLUE}数据库监控:${NC} http://localhost:8080/druid/"
    separator
    log_cyan "默认登录账号："
    echo -e "• ${BLUE}用户名:${NC} admin"
    echo -e "• ${BLUE}密码:${NC}   admin123"
    separator
    log_warning "按 Ctrl+C 停止所有服务"
}

# 停止服务
stop_services() {
    log_info "\n正在停止所有服务..."

    # 停止后端服务
    if [ -f "$PROJECT_ROOT/logs/backend.pid" ]; then
        local backend_pid=$(cat "$PROJECT_ROOT/logs/backend.pid")
        if kill -0 $backend_pid 2>/dev/null; then
            kill $backend_pid
            log_success "✓ 后端服务已停止"
        fi
        rm -f "$PROJECT_ROOT/logs/backend.pid"
    fi

    # 停止前端服务
    if [ -f "$PROJECT_ROOT/logs/frontend.pid" ]; then
        local frontend_pid=$(cat "$PROJECT_ROOT/logs/frontend.pid")
        if kill -0 $frontend_pid 2>/dev/null; then
            kill $frontend_pid
            log_success "✓ 前端服务已停止"
        fi
        rm -f "$PROJECT_ROOT/logs/frontend.pid"
    fi

    # 停止 Docker 容器
    cd "$PROJECT_ROOT/mysql-env"
    docker-compose down 2>/dev/null
    cd "$PROJECT_ROOT/redis-dev"
    docker-compose down 2>/dev/null
    log_success "✓ Docker 容器已停止"

    log_success "所有服务已停止"
    exit 0
}

# 监控服务状态
monitor_services() {
    local backend_pid=$1
    local frontend_pid=$2

    # 设置信号处理
    trap stop_services SIGINT SIGTERM

    while true; do
        # 检查进程状态
        if ! kill -0 $backend_pid 2>/dev/null; then
            log_warning "后端服务异常退出"
            stop_services
        fi

        if ! kill -0 $frontend_pid 2>/dev/null; then
            log_warning "前端服务异常退出"
            stop_services
        fi

        # 显示服务运行状态
        local timestamp=$(date "+%H:%M:%S")
        echo -ne "\r${CYAN}RuoYi 服务运行中 - 时间: $timestamp${NC}"

        sleep 10
    done
}

# 主函数
main() {
    log_cyan "🚀 RuoYi 项目一键启动脚本 ($(uname))"

    # 创建日志目录
    mkdir -p "$PROJECT_ROOT/logs"

    separator

    # 环境检查
    check_environment

    separator

    # 启动服务
    if ! start_docker_services; then
        log_error "Docker 服务启动失败，请检查 Docker 安装和配置"
        exit 1
    fi

    local backend_pid=$(start_backend)
    if [ $? -ne 0 ] || [ -z "$backend_pid" ]; then
        log_error "后端服务启动失败"
        exit 1
    fi

    local frontend_pid=$(start_frontend)
    if [ $? -ne 0 ] || [ -z "$frontend_pid" ]; then
        log_error "前端服务启动失败"
        kill $backend_pid 2>/dev/null
        exit 1
    fi

    # 显示服务状态
    show_service_status

    # 监控服务状态
    monitor_services $backend_pid $frontend_pid
}

# 错误处理
set -e
trap 'log_error "脚本执行出现错误，正在清理..."; stop_services' ERR

# 检查操作系统
if [[ "$OSTYPE" != "linux-gnu"* && "$OSTYPE" != "darwin"* ]]; then
    log_error "此脚本仅支持 Linux 和 macOS 系统"
    exit 1
fi

# 运行主函数
main "$@"
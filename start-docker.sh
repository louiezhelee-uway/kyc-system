#!/bin/bash

# KYC 系统 Docker 启动脚本
# 用法: ./start-docker.sh [start|stop|restart|logs|shell|test]

set -e

PROJECT_NAME="kyc"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装。请先安装 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装。请先安装 Docker Compose"
        exit 1
    fi
    
    print_success "Docker 已安装"
}

# 检查 .env 文件
check_env() {
    if [ ! -f .env ]; then
        print_warning ".env 文件不存在"
        print_info "正在从 .env.docker 创建 .env 文件..."
        
        if [ -f .env.docker ]; then
            cp .env.docker .env
            print_success ".env 文件已创建"
            print_warning "请编辑 .env 文件，填入实际的配置值"
        else
            print_error ".env.docker 文件不存在"
            exit 1
        fi
    fi
}

# 启动服务
start_services() {
    print_header "启动 KYC 系统"
    
    check_docker
    check_env
    
    print_info "构建镜像..."
    docker-compose build
    
    print_info "启动服务..."
    docker-compose up -d
    
    print_success "服务已启动"
    
    print_info "等待服务准备好..."
    sleep 5
    
    # 检查服务状态
    print_header "服务状态"
    docker-compose ps
    
    print_success "启动完成！"
    print_info "访问地址: http://localhost"
    print_info "API 地址: http://localhost/api"
    print_info "数据库: localhost:5432"
    
    print_header "下一步"
    print_info "查看日志: ./start-docker.sh logs"
    print_info "进入容器: ./start-docker.sh shell"
    print_info "停止服务: ./start-docker.sh stop"
}

# 停止服务
stop_services() {
    print_header "停止 KYC 系统"
    
    print_info "停止所有容器..."
    docker-compose down
    
    print_success "服务已停止"
}

# 重启服务
restart_services() {
    print_header "重启 KYC 系统"
    
    stop_services
    echo ""
    start_services
}

# 查看日志
view_logs() {
    print_header "KYC 系统日志"
    
    if [ -z "$2" ]; then
        print_info "查看所有服务日志 (按 Ctrl+C 退出)..."
        docker-compose logs -f
    else
        case $2 in
            web)
                print_info "查看 Flask 应用日志..."
                docker-compose logs -f web
                ;;
            postgres)
                print_info "查看 PostgreSQL 日志..."
                docker-compose logs -f postgres
                ;;
            nginx)
                print_info "查看 Nginx 日志..."
                docker-compose logs -f nginx
                ;;
            *)
                print_error "未知服务: $2"
                echo "可用服务: web, postgres, nginx"
                exit 1
                ;;
        esac
    fi
}

# 进入容器
enter_shell() {
    print_header "进入 Flask 容器"
    
    docker-compose exec web bash
}

# 测试系统
test_system() {
    print_header "测试 KYC 系统"
    
    # 检查 web 容器
    print_info "检查 Flask 应用..."
    if docker-compose exec -T web curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_success "Flask 应用运行正常"
    else
        print_warning "Flask 应用未响应"
    fi
    
    # 检查数据库
    print_info "检查 PostgreSQL..."
    if docker-compose exec -T postgres psql -U kyc_user -d kyc_db -c "SELECT 1" > /dev/null 2>&1; then
        print_success "PostgreSQL 运行正常"
    else
        print_error "PostgreSQL 连接失败"
    fi
    
    # 显示容器状态
    print_header "容器状态"
    docker-compose ps
    
    print_header "系统信息"
    print_info "Web 服务: http://localhost"
    print_info "数据库: postgres:5432"
    
    # 显示可用的 API 端点
    print_header "可用的 API 端点"
    print_info "POST   /webhook/taobao/order - 接收订单事件"
    print_info "POST   /webhook/sumsub/verification - 接收验证结果"
    print_info "GET    /verify/<token> - 验证页面"
    print_info "GET    /report/<order_id> - 报告页面"
    print_info "GET    /report/<order_id>/download - 下载 PDF"
}

# 清理系统
cleanup_system() {
    print_header "清理 Docker 资源"
    
    print_warning "这将删除所有 Docker 容器、镜像和数据"
    read -p "确认删除? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "停止容器..."
        docker-compose down -v
        
        print_info "删除镜像..."
        docker-compose down --rmi all
        
        print_success "清理完成"
    else
        print_info "取消清理"
    fi
}

# 数据库操作
database_operations() {
    case $2 in
        backup)
            print_header "备份数据库"
            BACKUP_DIR="./backups"
            mkdir -p $BACKUP_DIR
            TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
            print_info "备份到 $BACKUP_DIR/backup_$TIMESTAMP.sql"
            docker-compose exec -T postgres pg_dump -U kyc_user kyc_db > $BACKUP_DIR/backup_$TIMESTAMP.sql
            print_success "备份完成"
            ;;
        restore)
            if [ -z "$3" ]; then
                print_error "请指定备份文件"
                echo "用法: ./start-docker.sh db restore <backup_file>"
                exit 1
            fi
            print_header "恢复数据库"
            print_warning "这将覆盖现有数据"
            read -p "确认恢复? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                docker-compose exec -T postgres psql -U kyc_user kyc_db < $3
                print_success "恢复完成"
            fi
            ;;
        shell)
            print_header "进入 PostgreSQL"
            docker-compose exec postgres psql -U kyc_user -d kyc_db
            ;;
        *)
            print_error "未知数据库操作: $2"
            echo "可用操作: backup, restore <file>, shell"
            exit 1
            ;;
    esac
}

# 显示帮助
show_help() {
    cat << EOF
${BLUE}KYC 系统 Docker 启动脚本${NC}

${BLUE}用法:${NC}
  ./start-docker.sh [命令] [选项]

${BLUE}命令:${NC}
  start              启动所有服务
  stop               停止所有服务
  restart            重启所有服务
  logs [service]     查看日志
  shell              进入 Flask 容器
  test               测试系统
  db <operation>     数据库操作
  clean              清理 Docker 资源
  help               显示此帮助信息

${BLUE}示例:${NC}
  ./start-docker.sh start              # 启动服务
  ./start-docker.sh logs web           # 查看 Flask 日志
  ./start-docker.sh shell              # 进入容器
  ./start-docker.sh db backup          # 备份数据库
  ./start-docker.sh db restore file.sql # 恢复数据库

${BLUE}服务:${NC}
  web        Flask 应用服务 (5000)
  postgres   PostgreSQL 数据库 (5432)
  nginx      Nginx 反向代理 (80/443)

${BLUE}环境变量:${NC}
  编辑 .env 文件配置以下变量:
  - DATABASE_URL
  - SUMSUB_API_KEY
  - WEBHOOK_SECRET
  - SECRET_KEY

${BLUE}更多信息:${NC}
  查看 DOCKER.md 了解完整文档

EOF
}

# 主程序
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        view_logs "$@"
        ;;
    shell)
        enter_shell
        ;;
    test)
        test_system
        ;;
    db)
        database_operations "$@"
        ;;
    clean)
        cleanup_system
        ;;
    help)
        show_help
        ;;
    *)
        print_error "未知命令: $1"
        show_help
        exit 1
        ;;
esac

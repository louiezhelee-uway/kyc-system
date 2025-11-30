.PHONY: help start stop restart logs shell test clean db-backup db-restore

# 颜色输出
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)KYC 系统 Makefile 命令$(NC)"
	@echo ""
	@echo "$(GREEN)启动/停止:$(NC)"
	@echo "  make start         - 启动所有服务"
	@echo "  make stop          - 停止所有服务"
	@echo "  make restart       - 重启所有服务"
	@echo ""
	@echo "$(GREEN)开发:$(NC)"
	@echo "  make logs          - 查看实时日志"
	@echo "  make shell         - 进入 Flask 容器"
	@echo "  make test          - 测试系统"
	@echo ""
	@echo "$(GREEN)数据库:$(NC)"
	@echo "  make db-backup     - 备份数据库"
	@echo "  make db-shell      - 进入数据库"
	@echo ""
	@echo "$(GREEN)维护:$(NC)"
	@echo "  make clean         - 清理 Docker 资源"
	@echo "  make build         - 构建镜像"
	@echo ""

start:
	@echo "$(BLUE)启动 KYC 系统...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✅ 服务已启动$(NC)"
	@echo "访问地址: http://localhost"

stop:
	@echo "$(BLUE)停止 KYC 系统...$(NC)"
	docker-compose down
	@echo "$(GREEN)✅ 服务已停止$(NC)"

restart: stop start

logs:
	docker-compose logs -f

shell:
	docker-compose exec web bash

test:
	@echo "$(BLUE)测试系统...$(NC)"
	@docker-compose exec -T web curl -s http://localhost:5000/health || echo "$(RED)应用未响应$(NC)"
	@docker-compose ps

clean:
	@echo "$(YELLOW)警告: 这将删除所有 Docker 资源和数据$(NC)"
	@read -p "确认? (y/N): " confirm && [ "$$confirm" = "y" ] && docker-compose down -v --rmi all || echo "取消"

build:
	docker-compose build

db-backup:
	@echo "$(BLUE)备份数据库...$(NC)"
	@mkdir -p backups
	@docker-compose exec -T postgres pg_dump -U kyc_user kyc_db > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ 备份完成$(NC)"

db-shell:
	docker-compose exec postgres psql -U kyc_user -d kyc_db

ps:
	docker-compose ps

.DEFAULT_GOAL := help

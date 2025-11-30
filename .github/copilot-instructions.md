# KYC 自动化验证系统 - Copilot 项目指南

## 项目概述

这是一个 Python Flask KYC 自动化验证系统，集成 Sumsub API，支持淘宝/闲鱼订单 Webhook 触发。

## 技术栈

- **后端框架**: Flask 2.3.3
- **数据库**: PostgreSQL
- **ORM**: SQLAlchemy
- **第三方服务**: Sumsub API
- **报告生成**: ReportLab
- **认证**: HMAC-SHA256 Webhook 签名

## 项目结构说明

```
app/
├── models/         # 数据库模型（Order, Verification, Report）
├── routes/         # API 路由（webhook, verification, report）
├── services/       # 业务逻辑（Sumsub 集成、PDF 生成）
├── templates/      # HTML 模板（验证页、报告页、错误页）
├── static/         # 静态文件（CSS、JS、图片）
└── utils/          # 工具函数（Token 生成等）
```

## 核心功能

1. **Webhook 接收**: 监听淘宝/闲鱼订单事件
2. **KYC 链接生成**: 调用 Sumsub API 生成唯一验证链接
3. **验证中间页**: 自定义的验证页面
4. **状态跟踪**: 实时追踪验证状态
5. **PDF 报告**: 验证完成后自动生成报告

## 数据库

- PostgreSQL 连接字符串配置在环境变量 `DATABASE_URL`
- 使用 SQLAlchemy ORM 管理数据
- 支持 Flask-Migrate 进行迁移管理

## 环境变量

必需配置项在 `.env` 文件中：
- `SUMSUB_API_KEY`: Sumsub API 密钥
- `DATABASE_URL`: PostgreSQL 连接字符串
- `WEBHOOK_SECRET`: Webhook 签名密钥

## 已完成的核心代码

- ✅ 数据库模型和 ORM
- ✅ API 路由和 Webhook 端点
- ✅ Sumsub 服务集成框架
- ✅ PDF 报告生成模块
- ✅ HTML 模板和前端页面
- ✅ Token 安全生成工具

## 待处理项

- 🔲 Sumsub SDK 完整集成（等待 SDK 文档）
- 🔲 异步任务处理（Celery）
- 🔲 管理后台
- 🔲 单元测试和集成测试
- 🔲 生产部署脚本

## 关键文件说明

### `app/__init__.py`
- Flask 应用工厂
- 数据库和迁移初始化
- 蓝图注册

### `app/models/`
- `order.py`: 订单信息存储
- `verification.py`: KYC 验证记录
- `report.py`: 验证报告

### `app/routes/webhook.py`
- POST `/webhook/taobao/order`: 接收订单事件
- POST `/webhook/sumsub/verification`: 接收验证结果

### `app/services/sumsub_service.py`
- `create_verification()`: 创建验证和生成链接
- `update_verification_status()`: 更新验证状态
- `generate_pdf_report()`: 生成 PDF 报告

## 开发建议

1. 验证 Sumsub SDK 后立即更新 `sumsub_service.py`
2. 使用 `requirements.txt` 管理依赖版本
3. 环境配置通过 `.env` 文件，不提交到版本控制
4. API 返回统一的 JSON 格式响应
5. 所有外部 API 调用加入错误处理

## 调试信息

- 启用 `FLASK_ENV=development` 获得详细错误信息
- PostgreSQL 日志位置：通常在系统日志目录
- 应用日志建议集成到 `app.logger`

## 下一步

1. 请提供 Sumsub SDK 文档
2. 完善 SDK 集成
3. 编写单元测试
4. 配置部署环境

---

项目启动: 2025-11-23

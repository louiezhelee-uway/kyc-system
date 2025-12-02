#!/bin/bash

###############################################################################
# VPS Flask 应用诊断脚本
# 检查 Flask 应用启动和运行状态
###############################################################################

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Flask 应用诊断                                       ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 检查 Flask 容器日志
echo "📋 Flask 容器最新日志 (50 行):"
echo "════════════════════════════════════════════════════════"
docker logs --tail=50 kyc_web 2>&1 | tail -50
echo ""

# 检查 PostgreSQL 连接
echo "🔗 检查 PostgreSQL 连接:"
echo "════════════════════════════════════════════════════════"
docker exec kyc_postgres pg_isready -U kyc_user -d kyc_db || echo "❌ PostgreSQL 连接失败"
echo ""

# 检查环境变量
echo "🔐 检查 Flask 容器中的环境变量:"
echo "════════════════════════════════════════════════════════"
docker exec kyc_web env | grep -E "^(DATABASE_URL|SUMSUB|FLASK|APP_DOMAIN|WEBHOOK)" || echo "未找到关键环境变量"
echo ""

# 尝试进入 Flask 容器运行 Python 诊断
echo "🐍 Python 环境诊断:"
echo "════════════════════════════════════════════════════════"
docker exec kyc_web python3 << 'EOF' 2>&1
import sys
import os

print("✅ Python 版本:", sys.version)
print("✅ Python 路径:", sys.executable)
print("")

# 检查必要的模块
modules = ['flask', 'sqlalchemy', 'psycopg2', 'requests']
for module in modules:
    try:
        __import__(module)
        print(f"✅ {module}: 已安装")
    except ImportError:
        print(f"❌ {module}: 未安装")

print("")
print("环境变量:")
for key in sorted(os.environ.keys()):
    if any(x in key for x in ['DATABASE', 'SUMSUB', 'FLASK', 'APP', 'WEBHOOK', 'SECRET']):
        value = os.environ[key]
        if len(value) > 30:
            value = value[:15] + '...' + value[-15:]
        print(f"  {key}: {value}")
EOF

echo ""

# 尝试连接数据库
echo "🗄️  数据库连接测试:"
echo "════════════════════════════════════════════════════════"
docker exec kyc_web python3 << 'EOF' 2>&1
import os
import sys

DATABASE_URL = os.getenv('DATABASE_URL')
if not DATABASE_URL:
    print("❌ DATABASE_URL 未设置")
    sys.exit(1)

print(f"📌 DATABASE_URL: {DATABASE_URL}")
print("")

try:
    from sqlalchemy import create_engine, text
    engine = create_engine(DATABASE_URL, echo=False)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("✅ 数据库连接成功")
        
        # 查询表
        result = conn.execute(text("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        """))
        tables = result.fetchall()
        if tables:
            print(f"✅ 找到 {len(tables)} 个表:")
            for table in tables:
                print(f"   - {table[0]}")
        else:
            print("⚠️  未找到任何表")
except Exception as e:
    print(f"❌ 数据库连接失败: {e}")
    import traceback
    traceback.print_exc()
EOF

echo ""

# 检查 Flask 应用启动
echo "🚀 Flask 应用启动测试:"
echo "════════════════════════════════════════════════════════"
docker exec kyc_web python3 << 'EOF' 2>&1
try:
    from app import create_app
    app = create_app()
    print("✅ Flask 应用创建成功")
    
    with app.app_context():
        from app import db
        print("✅ 数据库连接成功")
        
        # 列出已注册的路由
        print("")
        print("已注册的路由:")
        for rule in sorted(app.url_map.iter_rules(), key=lambda r: str(r)):
            print(f"  {str(rule.rule):40} -> {rule.endpoint}")
            
except Exception as e:
    print(f"❌ Flask 应用启动失败: {e}")
    import traceback
    traceback.print_exc()
EOF

echo ""
echo "════════════════════════════════════════════════════════"
echo "诊断完成"

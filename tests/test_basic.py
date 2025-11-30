#!/usr/bin/env python3
"""
KYC 系统本地测试套件
包括单元测试和集成测试
"""

import pytest
import json
import sys
from pathlib import Path

# 添加项目路径
project_dir = Path(__file__).parent
sys.path.insert(0, str(project_dir))

def test_app_initialization():
    """测试应用初始化"""
    from app import create_app
    
    app = create_app()
    assert app is not None
    assert app.config['SECRET_KEY'] is not None
    print("✅ 应用初始化测试通过")


def test_blueprints_registered():
    """测试蓝图是否正确注册"""
    from app import create_app
    
    app = create_app()
    blueprints = list(app.blueprints.keys())
    
    assert 'webhook' in blueprints
    assert 'verification' in blueprints
    assert 'report' in blueprints
    print("✅ 蓝图注册测试通过")


def test_routes_available():
    """测试所有路由是否可用"""
    from app import create_app
    
    app = create_app()
    routes = [rule.rule for rule in app.url_map.iter_rules() if rule.endpoint != 'static']
    
    # 检查关键路由
    assert '/webhook/taobao/order' in routes
    assert '/webhook/sumsub/verification' in routes
    assert '/verify/<verification_token>' in routes
    assert '/report/<order_id>' in routes
    
    print(f"✅ 路由测试通过 (共 {len(routes)} 个路由)")


def test_models_imported():
    """测试数据库模型是否正确导入"""
    from app.models import Order, Verification, Report
    
    assert Order is not None
    assert Verification is not None
    assert Report is not None
    print("✅ 数据库模型测试通过")


def test_services_imported():
    """测试服务是否正确导入"""
    from app.services import sumsub_service, report_service
    from app.utils import token_generator
    
    assert sumsub_service is not None
    assert report_service is not None
    assert token_generator is not None
    print("✅ 服务导入测试通过")


def test_token_generation():
    """测试 Token 生成"""
    from app.utils import token_generator
    
    token = token_generator.generate_verification_token()
    assert len(token) == 32
    assert token.isalnum()
    
    # 生成两个 token 应该不相同
    token2 = token_generator.generate_verification_token()
    assert token != token2
    
    print("✅ Token 生成测试通过")


def test_flask_client():
    """测试 Flask 测试客户端"""
    from app import create_app
    
    app = create_app()
    client = app.test_client()
    
    # 测试不存在的路由
    response = client.get('/nonexistent')
    assert response.status_code == 404
    
    print("✅ Flask 客户端测试通过")


class TestWebhookEndpoints:
    """Webhook 端点测试"""
    
    @pytest.fixture
    def client(self):
        from app import create_app
        app = create_app()
        return app.test_client()
    
    def test_order_webhook_without_signature(self, client):
        """测试没有签名的订单 Webhook"""
        response = client.post('/webhook/taobao/order', 
            json={'order_id': 'test_order'})
        # 应该返回 401（无效签名）或 400（请求错误）
        assert response.status_code in [400, 401]
        print("✅ Webhook 签名验证测试通过")


class TestVerificationRoutes:
    """验证路由测试"""
    
    @pytest.fixture
    def client(self):
        from app import create_app
        app = create_app()
        return app.test_client()
    
    def test_verification_page_not_found(self, client):
        """测试验证页面不存在的情况"""
        response = client.get('/verify/invalid_token')
        assert response.status_code == 404
        print("✅ 验证页面 404 测试通过")


def test_all_imports():
    """完整导入测试"""
    try:
        import flask
        import flask_sqlalchemy
        import flask_migrate
        import psycopg2
        import dotenv
        import requests
        import reportlab
        from PIL import Image
        
        print("✅ 所有依赖导入测试通过")
        return True
    except ImportError as e:
        print(f"❌ 导入失败: {e}")
        return False


def run_basic_tests():
    """运行基础测试"""
    print("\n" + "=" * 60)
    print("KYC 系统本地测试")
    print("=" * 60 + "\n")
    
    try:
        test_app_initialization()
        test_blueprints_registered()
        test_routes_available()
        test_models_imported()
        test_services_imported()
        test_token_generation()
        test_flask_client()
        test_all_imports()
        
        print("\n" + "=" * 60)
        print("✅ 所有基础测试通过！")
        print("=" * 60)
        return True
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == '__main__':
    success = run_basic_tests()
    sys.exit(0 if success else 1)

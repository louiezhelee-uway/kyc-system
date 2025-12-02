from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import os
from dotenv import load_dotenv

load_dotenv()

db = SQLAlchemy()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    
    # Configuration
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'postgresql://localhost/kyc_db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    
    # Health check endpoint
    @app.route('/health')
    def health_check():
        """健康检查端点"""
        return jsonify({
            'status': 'healthy',
            'service': 'KYC Verification System',
            'version': '1.0.0'
        }), 200
    
    # Register blueprints
    try:
        from app.routes import webhook
        app.register_blueprint(webhook.bp)
        print("✅ webhook 蓝图已注册")
    except Exception as e:
        print(f"❌ webhook 蓝图注册失败: {e}")
        import traceback
        traceback.print_exc()
    
    try:
        from app.routes import verification
        app.register_blueprint(verification.bp)
        print("✅ verification 蓝图已注册")
    except Exception as e:
        print(f"❌ verification 蓝图注册失败: {e}")
        import traceback
        traceback.print_exc()
    
    try:
        from app.routes import report
        app.register_blueprint(report.bp)
        print("✅ report 蓝图已注册")
    except Exception as e:
        print(f"❌ report 蓝图注册失败: {e}")
        import traceback
        traceback.print_exc()
    
    # Global error handler
    @app.errorhandler(Exception)
    def handle_exception(error):
        """全局异常处理"""
        import traceback
        
        # 打印完整的错误堆栈到控制台
        print(f"\n❌ 应用异常: {error}")
        traceback.print_exc()
        print()
        
        # 返回错误详情
        return jsonify({
            'error': str(error),
            'type': type(error).__name__,
            'status': 'error'
        }), 500
    
    # Create tables
    with app.app_context():
        try:
            db.create_all()
            print("✅ 数据库表已创建或已存在")
        except Exception as e:
            print(f"⚠️  警告: 无法创建数据库表: {e}")
            # 仍然继续，让应用运行
            # 在 DEBUG 模式下打印完整的错误堆栈
            if os.getenv('FLASK_DEBUG') == '1':
                import traceback
                traceback.print_exc()
    
    return app

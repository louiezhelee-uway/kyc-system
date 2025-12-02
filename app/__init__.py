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
    from app.routes import webhook, verification, report
    app.register_blueprint(webhook.bp)
    app.register_blueprint(verification.bp)
    app.register_blueprint(report.bp)
    
    # Create tables (only in development, skip if database connection fails)
    with app.app_context():
        try:
            db.create_all()
        except Exception as e:
            if os.getenv('FLASK_ENV') == 'development':
                app.logger.warning(f"无法创建数据库表: {e}")
            else:
                raise
    
    return app

from app import db
from datetime import datetime
import uuid

class Order(db.Model):
    __tablename__ = 'orders'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    taobao_order_id = db.Column(db.String(255), unique=True, nullable=False, index=True)
    buyer_id = db.Column(db.String(255), nullable=False)
    buyer_name = db.Column(db.String(255), nullable=False)
    buyer_email = db.Column(db.String(255), nullable=False)
    buyer_phone = db.Column(db.String(20))
    platform = db.Column(db.String(50), nullable=False)  # 'taobao' or 'xianyu'
    order_amount = db.Column(db.Float)
    order_date = db.Column(db.DateTime, default=datetime.utcnow)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    verification = db.relationship('Verification', backref='order', uselist=False, cascade='all, delete-orphan')
    report = db.relationship('Report', backref='order', uselist=False, cascade='all, delete-orphan')
    
    def __repr__(self):
        return f'<Order {self.taobao_order_id}>'

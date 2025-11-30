from app import db
from datetime import datetime
import uuid

class Verification(db.Model):
    __tablename__ = 'verifications'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = db.Column(db.String(36), db.ForeignKey('orders.id'), nullable=False, unique=True)
    sumsub_applicant_id = db.Column(db.String(255), unique=True, nullable=False, index=True)
    verification_link = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(50), default='pending')  # pending, approved, rejected, expired
    verification_token = db.Column(db.String(255), unique=True, nullable=False)
    started_at = db.Column(db.DateTime)
    completed_at = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Verification {self.sumsub_applicant_id}>'

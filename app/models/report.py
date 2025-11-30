from app import db
from datetime import datetime
import uuid

class Report(db.Model):
    __tablename__ = 'reports'
    
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    order_id = db.Column(db.String(36), db.ForeignKey('orders.id'), nullable=False, unique=True)
    verification_result = db.Column(db.String(50))  # approved, rejected, pending
    verification_details = db.Column(db.JSON)
    pdf_url = db.Column(db.String(512))
    pdf_path = db.Column(db.String(512))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Report {self.id}>'

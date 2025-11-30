from flask import Blueprint, render_template, send_file, jsonify
from app.models import Order, Report
import os

bp = Blueprint('report', __name__, url_prefix='/report')

@bp.route('/<order_id>', methods=['GET'])
def view_report(order_id):
    """
    View verification report page
    """
    try:
        order = Order.query.filter_by(id=order_id).first()
        
        if not order:
            return render_template('error.html', message='Order not found'), 404
        
        report = order.report
        
        if not report:
            return render_template('error.html', message='Report not available yet'), 404
        
        return render_template(
            'report.html',
            order=order,
            report=report
        ), 200
        
    except Exception as e:
        return render_template('error.html', message=str(e)), 500

@bp.route('/<order_id>/download', methods=['GET'])
def download_report(order_id):
    """
    Download PDF report
    """
    try:
        order = Order.query.filter_by(id=order_id).first()
        
        if not order:
            return jsonify({'error': 'Order not found'}), 404
        
        report = order.report
        
        if not report or not report.pdf_path:
            return jsonify({'error': 'PDF not available'}), 404
        
        if not os.path.exists(report.pdf_path):
            return jsonify({'error': 'PDF file not found'}), 404
        
        return send_file(
            report.pdf_path,
            as_attachment=True,
            download_name=f"kyc_report_{order_id}.pdf"
        )
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

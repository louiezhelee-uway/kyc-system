from flask import Blueprint, render_template, send_file, jsonify
from app.models import Order, Report, Verification
from app.services.sumsub_report_downloader import SumsubReportDownloader
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


# ========== 新增：Sumsub 报告下载接口 ==========

@bp.route('/sumsub/list/<verification_token>', methods=['GET'])
def list_sumsub_reports(verification_token):
    """
    列出某个验证的所有 Sumsub 报告
    
    Parameters:
        verification_token: 验证令牌
    
    Response:
        {
          "verification_id": 123,
          "order_id": 456,
          "order_number": "taobao_order_xxx",
          "status": "approved",
          "verified_at": "2025-12-08T10:30:00",
          "reports": [
            {
              "filename": "kyc_report_123_xxx_en.pdf",
              "lang": "en",
              "format": "pdf",
              "size": 123456,
              "created_at": "2025-12-08T10:30:00"
            }
          ],
          "report_count": 2
        }
    """
    try:
        # 查询验证记录
        verification = Verification.query.filter_by(
            verification_token=verification_token
        ).first()
        
        if not verification:
            return jsonify({'error': 'Verification not found'}), 404
        
        if verification.status != 'approved':
            return jsonify({
                'error': 'Verification not approved',
                'status': verification.status
            }), 403
        
        # 列出报告
        reports = SumsubReportDownloader.list_reports_for_verification(verification.id)
        
        order = Order.query.get(verification.order_id)
        
        return jsonify({
            'verification_id': verification.id,
            'order_id': verification.order_id,
            'order_number': order.taobao_order_id if order else None,
            'buyer_name': order.buyer_name if order else None,
            'status': verification.status,
            'verified_at': verification.updated_at.isoformat() if verification.updated_at else None,
            'reports': reports,
            'report_count': len(reports)
        }), 200
    
    except Exception as e:
        print(f"❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@bp.route('/sumsub/download/<verification_token>/<filename>', methods=['GET'])
def download_sumsub_report(verification_token, filename):
    """
    下载 Sumsub 报告文件
    
    Parameters:
        verification_token: 验证令牌
        filename: 报告文件名 (e.g., "kyc_report_123_xxx_en.pdf")
    
    Returns:
        File content with appropriate headers
    """
    try:
        # 查询验证记录
        verification = Verification.query.filter_by(
            verification_token=verification_token
        ).first()
        
        if not verification:
            return jsonify({'error': 'Verification not found'}), 404
        
        if verification.status != 'approved':
            return jsonify({
                'error': 'Verification not approved',
                'status': verification.status
            }), 403
        
        # 验证文件名安全性（防止目录穿越）
        if '..' in filename or '/' in filename or '\\' in filename:
            return jsonify({'error': 'Invalid filename'}), 400
        
        # 构建文件路径
        filepath = os.path.join(SumsubReportDownloader.REPORT_STORAGE_DIR, filename)
        
        # 验证文件存在且属于此验证
        if not os.path.exists(filepath):
            return jsonify({'error': 'Report file not found'}), 404
        
        # 验证文件属于此验证（文件名应包含 verification_id）
        if str(verification.id) not in filename:
            return jsonify({'error': 'Report not belong to this verification'}), 403
        
        # 确定文件类型
        if filename.endswith('.pdf'):
            mimetype = 'application/pdf'
        elif filename.endswith('.json'):
            mimetype = 'application/json'
        else:
            mimetype = 'application/octet-stream'
        
        print(f"📥 下载报告: {filename}")
        
        try:
            return send_file(
                filepath,
                mimetype=mimetype,
                as_attachment=True,
                download_name=filename
            )
        except Exception as e:
            print(f"❌ 文件发送失败: {e}")
            return jsonify({'error': 'Failed to send file'}), 500
    
    except Exception as e:
        print(f"❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@bp.route('/sumsub/preview/<verification_token>/<lang>', methods=['GET'])
def preview_sumsub_report(verification_token, lang='en'):
    """
    获取报告预览信息（用于前端展示）
    
    Parameters:
        verification_token: 验证令牌
        lang: 语言 (en, zh, 等)
    
    Response:
        {
          "verification_id": 123,
          "order_id": 456,
          "order_number": "taobao_order_xxx",
          "buyer_name": "买家名字",
          "status": "approved",
          "verified_at": "2025-12-08T10:30:00",
          "language": "en",
          "available_languages": ["en", "zh"],
          "pdf_url": "/report/sumsub/download/token/kyc_report_123_xxx_en.pdf",
          "pdf_size": 123456,
          "json_url": "/report/sumsub/download/token/kyc_report_123_xxx_en.json",
          "json_size": 456789
        }
    """
    try:
        # 查询验证记录
        verification = Verification.query.filter_by(
            verification_token=verification_token
        ).first()
        
        if not verification:
            return jsonify({'error': 'Verification not found'}), 404
        
        if verification.status != 'approved':
            return jsonify({
                'error': 'Verification not approved',
                'status': verification.status
            }), 403
        
        order = Order.query.get(verification.order_id)
        
        # 列出此语言的报告
        reports = SumsubReportDownloader.list_reports_for_verification(verification.id)
        
        # 过滤出指定语言的报告
        pdf_report = next((r for r in reports if r['lang'] == lang and r['format'] == 'pdf'), None)
        json_report = next((r for r in reports if r['format'] == 'json'), None)
        
        response = {
            'verification_id': verification.id,
            'order_id': verification.order_id,
            'order_number': order.taobao_order_id if order else None,
            'buyer_name': order.buyer_name if order else None,
            'status': verification.status,
            'verified_at': verification.updated_at.isoformat() if verification.updated_at else None,
            'language': lang,
            'available_languages': list(set(r['lang'] for r in reports))
        }
        
        # 添加下载链接
        if pdf_report:
            response['pdf_url'] = f"/report/sumsub/download/{verification_token}/{pdf_report['filename']}"
            response['pdf_size'] = pdf_report['size']
        
        if json_report:
            response['json_url'] = f"/report/sumsub/download/{verification_token}/{json_report['filename']}"
            response['json_size'] = json_report['size']
        
        return jsonify(response), 200
    
    except Exception as e:
        print(f"❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


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

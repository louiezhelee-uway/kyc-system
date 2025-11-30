from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak
from reportlab.pdfgen import canvas
from datetime import datetime
import os
from app.models import Order

REPORTS_DIR = os.path.join(os.path.dirname(__file__), '..', 'reports')

def ensure_reports_dir():
    """Ensure reports directory exists"""
    os.makedirs(REPORTS_DIR, exist_ok=True)

def generate_report_pdf(order: Order, verification_result: dict) -> str:
    """
    Generate PDF report for KYC verification
    
    Args:
        order: Order object
        verification_result: Verification result from Sumsub
    
    Returns:
        Path to generated PDF file
    """
    try:
        ensure_reports_dir()
        
        # Create PDF filename
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        pdf_filename = f"kyc_report_{order.id}_{timestamp}.pdf"
        pdf_path = os.path.join(REPORTS_DIR, pdf_filename)
        
        # Create PDF document
        doc = SimpleDocTemplate(pdf_path, pagesize=A4)
        elements = []
        
        # Get styles
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            textColor=colors.HexColor('#1f4788'),
            spaceAfter=30,
            alignment=1  # Center alignment
        )
        
        heading_style = ParagraphStyle(
            'CustomHeading',
            parent=styles['Heading2'],
            fontSize=14,
            textColor=colors.HexColor('#1f4788'),
            spaceAfter=12,
            spaceBefore=12
        )
        
        normal_style = ParagraphStyle(
            'CustomNormal',
            parent=styles['Normal'],
            fontSize=11,
            spaceAfter=6
        )
        
        # Add title
        elements.append(Paragraph("KYC 验证报告", title_style))
        elements.append(Spacer(1, 0.2*inch))
        
        # Add report metadata
        elements.append(Paragraph("报告信息", heading_style))
        
        report_info = [
            ['报告ID', order.id],
            ['生成时间', datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')],
            ['验证状态', order.verification.status.upper() if order.verification else 'N/A'],
        ]
        
        table = Table(report_info, colWidths=[2*inch, 4*inch])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#e8f0f8')),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        elements.append(table)
        elements.append(Spacer(1, 0.3*inch))
        
        # Add order information
        elements.append(Paragraph("订单信息", heading_style))
        
        order_info = [
            ['订单ID', order.taobao_order_id],
            ['平台', order.platform.upper()],
            ['买家名称', order.buyer_name],
            ['买家邮箱', order.buyer_email],
            ['订单金额', f"¥ {order.order_amount:.2f}" if order.order_amount else 'N/A'],
            ['订单日期', order.order_date.strftime('%Y-%m-%d %H:%M:%S') if order.order_date else 'N/A'],
        ]
        
        table2 = Table(order_info, colWidths=[2*inch, 4*inch])
        table2.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#e8f0f8')),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        elements.append(table2)
        elements.append(Spacer(1, 0.3*inch))
        
        # Add verification result
        elements.append(Paragraph("验证结果", heading_style))
        
        verification_status = order.verification.status.upper() if order.verification else 'UNKNOWN'
        status_color = colors.green if verification_status == 'APPROVED' else colors.red if verification_status == 'REJECTED' else colors.orange
        
        status_text = f"<font color='{status_color.hexval()}' size='14'><b>{verification_status}</b></font>"
        elements.append(Paragraph(status_text, normal_style))
        elements.append(Spacer(1, 0.1*inch))
        
        # Add detailed verification information
        if verification_result:
            elements.append(Paragraph("详细信息", heading_style))
            
            details_text = f"验证ID: {verification_result.get('id', 'N/A')}<br/>"
            if 'reviewStatus' in verification_result:
                details_text += f"审核状态: {verification_result.get('reviewStatus', 'N/A')}<br/>"
            
            elements.append(Paragraph(details_text, normal_style))
        
        elements.append(Spacer(1, 0.5*inch))
        
        # Add footer
        footer_text = "此报告由 KYC 自动验证系统生成，具有法律效力。"
        elements.append(Paragraph(footer_text, ParagraphStyle(
            'Footer',
            parent=styles['Normal'],
            fontSize=9,
            textColor=colors.grey,
            alignment=1
        )))
        
        # Build PDF
        doc.build(elements)
        
        return pdf_path
        
    except Exception as e:
        raise Exception(f'Failed to generate PDF: {str(e)}')

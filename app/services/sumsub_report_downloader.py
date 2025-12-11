"""
Sumsub 报告下载和集成服务
处理从 Sumsub 官方 API 下载的 KYC 验证报告
"""

import os
import requests
import hmac
import hashlib
import time
import json
from datetime import datetime
from app import db
from app.models import Verification

class SumsubReportDownloader:
    """Sumsub 报告下载器"""
    
    SUMSUB_APP_TOKEN = os.getenv('SUMSUB_APP_TOKEN')
    SUMSUB_SECRET_KEY = os.getenv('SUMSUB_SECRET_KEY')
    SUMSUB_API_URL = os.getenv('SUMSUB_API_URL', 'https://api.sumsub.com')
    
    # 报告存储目录
    REPORT_STORAGE_DIR = '/opt/kyc-app/reports/sumsub'
    
    @staticmethod
    def _ensure_storage_dir():
        """确保报告存储目录存在"""
        if not os.path.exists(SumsubReportDownloader.REPORT_STORAGE_DIR):
            os.makedirs(SumsubReportDownloader.REPORT_STORAGE_DIR, exist_ok=True)
    
    @staticmethod
    def _get_signature(method: str, path: str, body: str = ''):
        """
        生成 Sumsub API 签名
        格式：{timestamp}{method}{path}{body}，timestamp 为秒级 Unix Epoch
        """
        if not SumsubReportDownloader.SUMSUB_SECRET_KEY:
            raise Exception('SUMSUB_SECRET_KEY is not configured')
        
        ts = str(int(time.time()))  # 秒级时间戳
        request_body = body if body else ''
        signature_raw = f"{ts}{method}{path}{request_body}"
        
        signature = hmac.new(
            SumsubReportDownloader.SUMSUB_SECRET_KEY.encode(),
            signature_raw.encode(),
            hashlib.sha256
        ).hexdigest()
        
        return ts, signature
    
    @staticmethod
    def download_report(applicant_id, report_type='applicantReport', lang='en', output_format='pdf'):
        """
        从 Sumsub 下载报告
        隐藏 API: GET /resources/applicants/{applicantId}/summary/report?report=applicantReport&lang={lang}
        
        参数：
            applicant_id: 申请人 ID（来自 Sumsub）
            report_type: 报告类型，默认 'applicantReport'
            lang: 语言代码 ('en', 'zh', 'ru', 'es', 等)
            output_format: 输出格式 ('pdf', 'json')
        
        返回：
            bytes: 报告二进制内容，或 None 如果失败
        """
        
        path = f"/resources/applicants/{applicant_id}/summary/report"
        
        # 查询参数
        params = {
            'report': report_type,
            'lang': lang
        }
        
        # 生成签名
        ts, signature = SumsubReportDownloader._get_signature('GET', path)
        
        # 请求头
        headers = {
            'X-App-Token': SumsubReportDownloader.SUMSUB_APP_TOKEN,
            'X-App-Access-Sig': signature,
            'X-App-Access-Ts': ts,
            'Accept': 'application/pdf' if output_format == 'pdf' else 'application/json'
        }
        
        print(f"📥 下载 Sumsub 报告: {applicant_id}")
        print(f"   Language: {lang}, Format: {output_format}")
        
        try:
            response = requests.get(
                f"{SumsubReportDownloader.SUMSUB_API_URL}{path}",
                params=params,
                headers=headers,
                timeout=30
            )
            
            print(f"   HTTP Status: {response.status_code}")
            
            if response.status_code == 200:
                print(f"✅ 报告下载成功 ({len(response.content)} bytes)")
                return response.content
            else:
                error_msg = response.text[:500] if response.text else "Unknown error"
                print(f"❌ 报告下载失败")
                print(f"   Error: {error_msg}")
                return None
        
        except Exception as e:
            print(f"❌ 下载异常: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    @staticmethod
    def save_report(verification_id, applicant_id, report_content, format='pdf', lang='en'):
        """
        保存报告到本地文件系统
        
        参数：
            verification_id: 验证 ID（我们数据库中的）
            applicant_id: 申请人 ID（Sumsub 的）
            report_content: 报告内容（字节）
            format: 格式 ('pdf', 'json')
            lang: 语言
        
        返回：
            str: 报告文件路径，或 None 如果失败
        """
        
        SumsubReportDownloader._ensure_storage_dir()
        
        # 构建文件名：kyc_report_{verification_id}_{applicant_id}_{lang}.{format}
        filename = f"kyc_report_{verification_id}_{applicant_id}_{lang}.{format}"
        filepath = os.path.join(SumsubReportDownloader.REPORT_STORAGE_DIR, filename)
        
        try:
            with open(filepath, 'wb') as f:
                f.write(report_content)
            
            print(f"✅ 报告已保存: {os.path.basename(filepath)}")
            print(f"   Path: {filepath}")
            return filepath
        
        except Exception as e:
            print(f"❌ 保存失败: {e}")
            return None
    
    @staticmethod
    def auto_download_on_approval(verification_id, applicant_id, languages=['en']):
        """
        验证批准后自动下载多语言报告
        
        参数：
            verification_id: 验证 ID
            applicant_id: 申请人 ID
            languages: 要下载的语言列表
        
        返回：
            dict: {
                'en_pdf': '/path/to/report.pdf',
                'zh_pdf': '/path/to/report_zh.pdf',
                'json': '/path/to/report.json'
            }
        """
        
        report_files = {}
        
        print(f"\n" + "="*60)
        print(f"📋 自动下载验证报告")
        print(f"   Verification ID: {verification_id}")
        print(f"   Applicant ID: {applicant_id}")
        print(f"   Languages: {', '.join(languages)}")
        print(f"="*60)
        
        # 下载每种语言的 PDF
        for lang in languages:
            pdf_content = SumsubReportDownloader.download_report(
                applicant_id,
                report_type='applicantReport',
                lang=lang,
                output_format='pdf'
            )
            
            if pdf_content:
                pdf_path = SumsubReportDownloader.save_report(
                    verification_id,
                    applicant_id,
                    pdf_content,
                    format='pdf',
                    lang=lang
                )
                if pdf_path:
                    report_files[f'{lang}_pdf'] = pdf_path
        
        # 下载 JSON（仅一份，使用第一种语言）
        if languages:
            json_content = SumsubReportDownloader.download_report(
                applicant_id,
                report_type='applicantReport',
                lang=languages[0],
                output_format='json'
            )
            
            if json_content:
                json_path = SumsubReportDownloader.save_report(
                    verification_id,
                    applicant_id,
                    json_content,
                    format='json',
                    lang=languages[0]
                )
                if json_path:
                    report_files['json'] = json_path
        
        print(f"\n✅ 报告下载完成: {len(report_files)} 个文件")
        print(f"   Files: {list(report_files.keys())}")
        print(f"="*60 + "\n")
        
        return report_files
    
    @staticmethod
    def get_report_url(verification_id, lang='en', format='pdf'):
        """
        获取报告文件路径（用于返回给 API 客户端）
        
        返回：
            str: 相对路径 '/reports/sumsub/...'，用于 Flask 提供文件下载
        """
        
        filename = f"kyc_report_{verification_id}_*_{lang}.{format}"
        
        import glob
        files = glob.glob(os.path.join(SumsubReportDownloader.REPORT_STORAGE_DIR, filename))
        
        if files:
            basename = os.path.basename(files[0])
            return f"/reports/sumsub/{basename}"
        
        return None
    
    @staticmethod
    def list_reports_for_verification(verification_id):
        """
        列出某个验证的所有报告文件
        
        返回：
            list: [{'lang': 'en', 'format': 'pdf', 'path': '...', 'size': 123}, ...]
        """
        
        import glob
        pattern = os.path.join(SumsubReportDownloader.REPORT_STORAGE_DIR, f"kyc_report_{verification_id}_*")
        files = glob.glob(pattern)
        
        report_list = []
        for filepath in files:
            basename = os.path.basename(filepath)
            # 格式: kyc_report_{verification_id}_{applicant_id}_{lang}.{format}
            parts = basename.replace('kyc_report_', '').replace(f'{verification_id}_', '').split('.')
            
            if len(parts) >= 2:
                lang_part = parts[0].split('_')[-1]  # 获取最后一部分作为 lang
                format_type = parts[-1]
                
                report_list.append({
                    'filename': basename,
                    'lang': lang_part,
                    'format': format_type,
                    'path': filepath,
                    'size': os.path.getsize(filepath),
                    'created_at': datetime.fromtimestamp(os.path.getctime(filepath)).isoformat()
                })
        
        return report_list

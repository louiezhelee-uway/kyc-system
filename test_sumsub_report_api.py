#!/usr/bin/env python3
"""
测试 Sumsub Report API
隐藏 API 端点：{sumsub_root_url}/resources/applicants/{applicantId}/summary/report?report=applicantReport&lang=en

用于下载验证报告（PDF 或 JSON 格式）
"""

import os
import sys
import requests
import hmac
import hashlib
import time
import json

# 添加项目路径
sys.path.insert(0, '/opt/kyc-app')

from app import create_app, db
from app.models import Verification

# 配置
SUMSUB_APP_TOKEN = os.getenv('SUMSUB_APP_TOKEN')
SUMSUB_SECRET_KEY = os.getenv('SUMSUB_SECRET_KEY')
SUMSUB_API_URL = os.getenv('SUMSUB_API_URL', 'https://api.sumsub.com')

def _get_signature(method: str, path: str, body: str = ''):
    """生成 Sumsub API 签名"""
    if not SUMSUB_SECRET_KEY:
        raise Exception('SUMSUB_SECRET_KEY is not configured')
    
    ts = str(int(time.time()))  # 秒级时间戳
    request_body = body if body else ''
    signature_raw = f"{ts}{method}{path}{request_body}"
    
    signature = hmac.new(
        SUMSUB_SECRET_KEY.encode(),
        signature_raw.encode(),
        hashlib.sha256
    ).hexdigest()
    
    return ts, signature

def download_report(applicant_id, report_type='applicantReport', lang='en', output_format='pdf'):
    """
    下载验证报告
    
    参数：
        applicant_id: 申请人 ID
        report_type: 报告类型 (applicantReport, 等)
        lang: 语言 (en, ru, zh, 等)
        output_format: 输出格式 (pdf, json)
    
    返回：
        bytes: 报告内容（PDF 或 JSON 二进制数据）
    """
    
    # 构建 API 路径
    path = f"/resources/applicants/{applicant_id}/summary/report"
    
    # 查询参数
    params = {
        'report': report_type,
        'lang': lang
    }
    
    # 生成签名
    ts, signature = _get_signature('GET', path)
    
    # 请求头
    headers = {
        'X-App-Token': SUMSUB_APP_TOKEN,
        'X-App-Access-Sig': signature,
        'X-App-Access-Ts': ts,
        'Accept': 'application/pdf' if output_format == 'pdf' else 'application/json'
    }
    
    print(f"📡 下载报告...")
    print(f"   Applicant ID: {applicant_id}")
    print(f"   Report Type: {report_type}")
    print(f"   Language: {lang}")
    print(f"   Format: {output_format}")
    print(f"   URL: {SUMSUB_API_URL}{path}")
    
    try:
        response = requests.get(
            f"{SUMSUB_API_URL}{path}",
            params=params,
            headers=headers,
            timeout=30
        )
        
        print(f"\n✅ 状态码: {response.status_code}")
        
        if response.status_code == 200:
            print(f"✅ 报告下载成功！")
            print(f"   Content-Type: {response.headers.get('Content-Type')}")
            print(f"   Content-Length: {len(response.content)} bytes")
            return response.content
        else:
            print(f"❌ 下载失败")
            print(f"   Response: {response.text[:500]}")
            return None
    
    except Exception as e:
        print(f"❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return None

def test_with_latest_verification():
    """使用最新的验证记录测试报告下载"""
    
    print("=" * 60)
    print("Sumsub Report API 测试")
    print("=" * 60)
    print()
    
    # 创建 Flask 应用上下文
    app = create_app()
    
    with app.app_context():
        # 查询最新的已批准验证
        verification = Verification.query.filter_by(
            status='approved'
        ).order_by(Verification.updated_at.desc()).first()
        
        if not verification or not verification.applicant_id:
            print("❌ 没有找到已批准的验证记录")
            print("   请先完成至少一个 KYC 验证并获得批准状态")
            return
        
        applicant_id = verification.applicant_id
        print(f"📋 发现验证记录:")
        print(f"   Verification ID: {verification.id}")
        print(f"   Applicant ID: {applicant_id}")
        print(f"   Status: {verification.status}")
        print(f"   Updated At: {verification.updated_at}")
        print()
        
        # 1. 尝试下载 PDF 格式报告
        print("--- 测试 1: 下载 PDF 格式报告 ---")
        pdf_content = download_report(
            applicant_id,
            report_type='applicantReport',
            lang='en',
            output_format='pdf'
        )
        
        if pdf_content:
            # 保存 PDF 文件
            pdf_path = f"/tmp/kyc_report_{applicant_id}.pdf"
            with open(pdf_path, 'wb') as f:
                f.write(pdf_content)
            print(f"✅ PDF 已保存: {pdf_path}")
        print()
        
        # 2. 尝试下载 JSON 格式报告
        print("--- 测试 2: 下载 JSON 格式报告 ---")
        json_content = download_report(
            applicant_id,
            report_type='applicantReport',
            lang='en',
            output_format='json'
        )
        
        if json_content:
            # 保存 JSON 文件
            json_path = f"/tmp/kyc_report_{applicant_id}.json"
            with open(json_path, 'wb') as f:
                f.write(json_content)
            print(f"✅ JSON 已保存: {json_path}")
            
            # 解析并显示
            try:
                data = json.loads(json_content)
                print(f"✅ JSON 内容预览:")
                print(json.dumps(data, indent=2, ensure_ascii=False)[:500])
            except:
                pass
        print()
        
        # 3. 尝试其他语言
        print("--- 测试 3: 下载中文报告 ---")
        zh_content = download_report(
            applicant_id,
            report_type='applicantReport',
            lang='zh',
            output_format='pdf'
        )
        
        if zh_content:
            zh_path = f"/tmp/kyc_report_{applicant_id}_zh.pdf"
            with open(zh_path, 'wb') as f:
                f.write(zh_content)
            print(f"✅ 中文 PDF 已保存: {zh_path}")
        print()
        
        print("=" * 60)
        print("✅ 测试完成！")
        print("=" * 60)

if __name__ == '__main__':
    test_with_latest_verification()

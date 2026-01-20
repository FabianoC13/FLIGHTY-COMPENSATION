#!/usr/bin/env python3
"""
Flighty Compensation Email Server
=================================
HTTP server that receives email requests from the iOS app and sends them via Gmail.

Run:
    python3 email_server.py
"""

import os
import json
import smtplib
import ssl
import base64
from http.server import HTTPServer, BaseHTTPRequestHandler
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

# === Configuration ===
PORT = 8080
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

# Load credentials from environment
GMAIL_ADDRESS = os.environ.get("GMAIL_ADDRESS", "")
GMAIL_APP_PASSWORD = os.environ.get("GMAIL_APP_PASSWORD", "")


def send_email(data: dict) -> tuple[bool, str]:
    """Send an email using Gmail SMTP."""
    if not GMAIL_ADDRESS or not GMAIL_APP_PASSWORD:
        return False, "Gmail credentials not set"
    
    try:
        msg = MIMEMultipart()
        msg["From"] = GMAIL_ADDRESS
        msg["To"] = data["to"]
        if data.get("cc"):
            msg["Cc"] = data["cc"]
        msg["Subject"] = data["subject"]
        
        # Body
        msg.attach(MIMEText(data["body"], "plain"))
        
        # Attachments (base64 encoded PDFs)
        for attachment in data.get("attachments", []):
            pdf_data = base64.b64decode(attachment["data"])
            part = MIMEApplication(pdf_data, Name=attachment["filename"])
            part["Content-Disposition"] = f'attachment; filename="{attachment["filename"]}"'
            msg.attach(part)
            print(f"   📎 Attached: {attachment['filename']}")
        
        # Send
        recipients = [data["to"]]
        if data.get("cc"):
            recipients.append(data["cc"])
        
        context = ssl.create_default_context()
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls(context=context)
            server.login(GMAIL_ADDRESS, GMAIL_APP_PASSWORD)
            server.sendmail(GMAIL_ADDRESS, recipients, msg.as_string())
        
        return True, f"Email sent to {data['to']}"
        
    except Exception as e:
        return False, str(e)


class EmailHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/send-email":
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode("utf-8"))
                print(f"\n📨 Received email request:")
                print(f"   To: {data.get('to')}")
                print(f"   Subject: {data.get('subject')}")
                
                success, message = send_email(data)
                
                if success:
                    print(f"✅ {message}")
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(json.dumps({"success": True, "message": message}).encode())
                else:
                    print(f"❌ {message}")
                    self.send_response(500)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(json.dumps({"success": False, "error": message}).encode())
                    
            except Exception as e:
                print(f"❌ Error: {e}")
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "error": str(e)}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass


def main():
    print("=" * 50)
    print("🚀 Flighty Compensation Email Server")
    print("=" * 50)
    print(f"📡 Listening on: http://localhost:{PORT}")
    print(f"📧 Sending from: {GMAIL_ADDRESS or '(not configured)'}")
    print("\nEndpoints:")
    print(f"  POST http://localhost:{PORT}/send-email")
    print(f"  GET  http://localhost:{PORT}/health")
    print("\nPress Ctrl+C to stop.\n")
    
    if not GMAIL_ADDRESS or not GMAIL_APP_PASSWORD:
        print("⚠️  WARNING: Gmail credentials not set!")
        print("   Set environment variables:")
        print("   export GMAIL_ADDRESS='your_email@gmail.com'")
        print("   export GMAIL_APP_PASSWORD='your_app_password'")
        print()
    
    server = HTTPServer(("", PORT), EmailHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Shutting down server.")
        server.shutdown()


if __name__ == "__main__":
    main()

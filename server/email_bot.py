#!/usr/bin/env python3
"""
Flighty Compensation Email Bot
==============================
Monitors /Users/fabiano/Documents/FlightyClaims/OutgoingEmails/ for new email requests
and sends them via Gmail SMTP.

Setup:
1. Enable "Less secure app access" in your Gmail account OR
2. Create an App Password at https://myaccount.google.com/apppasswords
   (Recommended: Use App Password with 2FA enabled)
3. Set your credentials in the .env file or environment variables:
   - GMAIL_ADDRESS=your_email@gmail.com
   - GMAIL_APP_PASSWORD=your_16_char_app_password

Run:
    python3 email_bot.py
"""

import os
import json
import time
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from pathlib import Path
from datetime import datetime

# === Configuration ===
WATCH_DIR = Path("/Users/fabiano/Documents/FlightyClaims/OutgoingEmails")
LEGAL_AUTHS_DIR = Path("/Users/fabiano/Documents/FlightyClaims/Legal_Authorizations")
COMPLAINTS_DIR = Path("/Users/fabiano/Documents/FlightyClaims/Airline_Complaints")
SENT_DIR = WATCH_DIR / "Sent"
FAILED_DIR = WATCH_DIR / "Failed"

# Gmail SMTP settings
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

# Load credentials from environment (or hardcode for testing)
GMAIL_ADDRESS = os.environ.get("GMAIL_ADDRESS", "")
GMAIL_APP_PASSWORD = os.environ.get("GMAIL_APP_PASSWORD", "")


def setup_dirs():
    """Ensure all required directories exist."""
    for d in [WATCH_DIR, SENT_DIR, FAILED_DIR]:
        d.mkdir(parents=True, exist_ok=True)


def find_attachment(filename: str) -> Path | None:
    """Search for attachment in known folders."""
    for folder in [LEGAL_AUTHS_DIR, COMPLAINTS_DIR, WATCH_DIR.parent]:
        candidate = folder / filename
        if candidate.exists():
            return candidate
    # Try direct path if filename is absolute
    direct = Path(filename)
    if direct.exists():
        return direct
    return None


def send_email(metadata: dict) -> bool:
    """Send an email using Gmail SMTP."""
    if not GMAIL_ADDRESS or not GMAIL_APP_PASSWORD:
        print("❌ Gmail credentials not set. Please set GMAIL_ADDRESS and GMAIL_APP_PASSWORD environment variables.")
        return False
    
    try:
        # Build message
        msg = MIMEMultipart()
        msg["From"] = GMAIL_ADDRESS
        msg["To"] = metadata["to"]
        if metadata.get("cc"):
            msg["Cc"] = metadata["cc"]
        msg["Subject"] = metadata["subject"]
        
        # Body
        msg.attach(MIMEText(metadata["body"], "plain"))
        
        # Attachments
        for attachment_name in metadata.get("attachments", []):
            attachment_path = find_attachment(attachment_name)
            if attachment_path:
                with open(attachment_path, "rb") as f:
                    part = MIMEApplication(f.read(), Name=attachment_path.name)
                    part["Content-Disposition"] = f'attachment; filename="{attachment_path.name}"'
                    msg.attach(part)
                print(f"   📎 Attached: {attachment_path.name}")
            else:
                print(f"   ⚠️ Attachment not found: {attachment_name}")
        
        # Send
        recipients = [metadata["to"]]
        if metadata.get("cc"):
            recipients.append(metadata["cc"])
        
        context = ssl.create_default_context()
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls(context=context)
            server.login(GMAIL_ADDRESS, GMAIL_APP_PASSWORD)
            server.sendmail(GMAIL_ADDRESS, recipients, msg.as_string())
        
        print(f"✅ Email sent to {metadata['to']}")
        return True
        
    except Exception as e:
        print(f"❌ Failed to send email: {e}")
        return False


def process_email_file(json_path: Path):
    """Process a single email metadata file."""
    print(f"\n📨 Processing: {json_path.name}")
    
    try:
        with open(json_path, "r") as f:
            metadata = json.load(f)
        
        # Check if already processed
        if metadata.get("status") == "sent":
            print("   Already sent, skipping.")
            return
        
        # Send email
        success = send_email(metadata)
        
        # Update status and move file
        metadata["status"] = "sent" if success else "failed"
        metadata["processedAt"] = datetime.now().isoformat()
        
        dest_dir = SENT_DIR if success else FAILED_DIR
        dest_path = dest_dir / json_path.name
        
        with open(dest_path, "w") as f:
            json.dump(metadata, f, indent=2)
        
        json_path.unlink()  # Remove from watch folder
        
        print(f"   Moved to: {dest_dir.name}/")
        
    except Exception as e:
        print(f"❌ Error processing {json_path.name}: {e}")


def watch_loop():
    """Main watch loop - polls for new email files."""
    print("=" * 50)
    print("🚀 Flighty Compensation Email Bot")
    print("=" * 50)
    print(f"📂 Watching: {WATCH_DIR}")
    print(f"📧 Sending from: {GMAIL_ADDRESS or '(not configured)'}")
    print("\nPress Ctrl+C to stop.\n")
    
    if not GMAIL_ADDRESS or not GMAIL_APP_PASSWORD:
        print("⚠️  WARNING: Gmail credentials not set!")
        print("   Set environment variables:")
        print("   export GMAIL_ADDRESS='your_email@gmail.com'")
        print("   export GMAIL_APP_PASSWORD='your_app_password'")
        print()
    
    setup_dirs()
    
    while True:
        try:
            # Find all pending email files
            json_files = list(WATCH_DIR.glob("email_*.json"))
            
            for json_path in json_files:
                process_email_file(json_path)
            
            # Sleep before next poll
            time.sleep(5)
            
        except KeyboardInterrupt:
            print("\n\n👋 Shutting down email bot.")
            break


if __name__ == "__main__":
    watch_loop()

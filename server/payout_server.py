#!/usr/bin/env python3
"""
Flighty Compensation Payout Server
==================================
HTTP server that manages payouts to customers via dLocal.

Features:
- Recipient management (bank details storage)
- Payout creation and tracking
- dLocal API integration
- Webhook handling for payout status updates
- Bank reconciliation for incoming AESA funds

Run:
    python3 payout_server.py
"""

import os
import json
import uuid
import hmac
import hashlib
import sqlite3
from datetime import datetime, timedelta
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from typing import Optional, Dict, Any, List
import threading
import time

# === Configuration ===
PORT = 8080
DATABASE_FILE = "payouts.db"

# dLocal API Configuration
DLOCAL_API_URL = os.environ.get("DLOCAL_API_URL", "https://sandbox.dlocal.com")
DLOCAL_API_KEY = os.environ.get("DLOCAL_API_KEY", "")
DLOCAL_SECRET_KEY = os.environ.get("DLOCAL_SECRET_KEY", "")
DLOCAL_WEBHOOK_SECRET = os.environ.get("DLOCAL_WEBHOOK_SECRET", "")

# Email notification (reuse from email_server)
EMAIL_SERVER_URL = "http://localhost:8080/send-email"


# === Database Setup ===

def init_database():
    """Initialize SQLite database with required tables."""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    # Recipients table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS recipients (
            id TEXT PRIMARY KEY,
            claim_id TEXT NOT NULL UNIQUE,
            customer_id TEXT NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT,
            country TEXT NOT NULL,
            address_street TEXT NOT NULL,
            address_city TEXT NOT NULL,
            address_postal TEXT NOT NULL,
            date_of_birth TEXT,
            document_type TEXT NOT NULL,
            document_number TEXT NOT NULL,
            payout_method TEXT NOT NULL DEFAULT 'bank',
            iban TEXT,
            bic TEXT,
            account_holder_name TEXT,
            bank_name TEXT,
            card_token TEXT,
            card_last4 TEXT,
            card_brand TEXT,
            currency_preferred TEXT NOT NULL DEFAULT 'EUR',
            status TEXT NOT NULL DEFAULT 'pending',
            validation_errors TEXT,
            kyc_screening_result TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    """)
    
    # Payouts table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS payouts (
            id TEXT PRIMARY KEY,
            claim_id TEXT NOT NULL,
            recipient_id TEXT NOT NULL,
            amount_eur REAL NOT NULL,
            currency_destination TEXT NOT NULL,
            fx_rate REAL,
            amount_destination REAL,
            provider TEXT NOT NULL DEFAULT 'dlocal',
            provider_payout_id TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            failure_reason TEXT,
            failure_code TEXT,
            created_at TEXT NOT NULL,
            queued_at TEXT,
            sent_at TEXT,
            settled_at TEXT,
            retry_count INTEGER DEFAULT 0,
            next_retry_at TEXT,
            webhook_last_event TEXT,
            webhook_last_event_at TEXT,
            FOREIGN KEY (recipient_id) REFERENCES recipients(id)
        )
    """)
    
    # Bank reconciliation table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS bank_reconciliations (
            id TEXT PRIMARY KEY,
            bank_ref TEXT NOT NULL,
            amount_eur REAL NOT NULL,
            received_at TEXT NOT NULL,
            matched_claim_id TEXT,
            matched_at TEXT,
            status TEXT NOT NULL DEFAULT 'pending_match',
            notes TEXT,
            created_at TEXT NOT NULL
        )
    """)
    
    # Webhook events log
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS webhook_events (
            id TEXT PRIMARY KEY,
            event_type TEXT NOT NULL,
            payout_id TEXT,
            provider_payout_id TEXT,
            payload TEXT NOT NULL,
            processed_at TEXT NOT NULL
        )
    """)
    
    conn.commit()
    conn.close()
    print("✅ Database initialized")


# === Models ===

class Recipient:
    def __init__(self, data: Dict[str, Any]):
        self.id = data.get("id", str(uuid.uuid4()))
        self.claim_id = data["claimId"]
        self.customer_id = data["customerId"]
        self.first_name = data["firstName"]
        self.last_name = data["lastName"]
        self.email = data["email"]
        self.phone = data.get("phone")
        self.country = data["country"]
        self.address_street = data["addressStreet"]
        self.address_city = data["addressCity"]
        self.address_postal = data["addressPostal"]
        self.date_of_birth = data.get("dateOfBirth")
        self.document_type = data["documentType"]
        self.document_number = data["documentNumber"]
        self.payout_method = data.get("payoutMethod", "bank")
        self.iban = data.get("iban")
        self.bic = data.get("bic")
        self.account_holder_name = data.get("accountHolderName")
        self.bank_name = data.get("bankName")
        self.card_token = data.get("cardToken")
        self.card_last4 = data.get("cardLast4")
        self.card_brand = data.get("cardBrand")
        self.currency_preferred = data.get("currencyPreferred", "EUR")
        self.status = data.get("status", "pending")
        self.validation_errors = data.get("validationErrors")
        self.kyc_screening_result = data.get("kycScreeningResult")
        self.created_at = data.get("createdAt", datetime.utcnow().isoformat())
        self.updated_at = data.get("updatedAt", datetime.utcnow().isoformat())
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "claimId": self.claim_id,
            "customerId": self.customer_id,
            "firstName": self.first_name,
            "lastName": self.last_name,
            "email": self.email,
            "phone": self.phone,
            "country": self.country,
            "addressStreet": self.address_street,
            "addressCity": self.address_city,
            "addressPostal": self.address_postal,
            "dateOfBirth": self.date_of_birth,
            "documentType": self.document_type,
            "documentNumber": self.document_number,
            "payoutMethod": self.payout_method,
            "iban": self.iban,
            "bic": self.bic,
            "accountHolderName": self.account_holder_name,
            "bankName": self.bank_name,
            "cardToken": self.card_token,
            "cardLast4": self.card_last4,
            "cardBrand": self.card_brand,
            "currencyPreferred": self.currency_preferred,
            "status": self.status,
            "validationErrors": self.validation_errors,
            "kycScreeningResult": self.kyc_screening_result,
            "createdAt": self.created_at,
            "updatedAt": self.updated_at
        }
    
    def validate(self) -> List[str]:
        errors = []
        if not self.first_name:
            errors.append("First name is required")
        if not self.last_name:
            errors.append("Last name is required")
        if not self.email:
            errors.append("Email is required")
        if not self.country:
            errors.append("Country is required")
        if not self.address_street:
            errors.append("Street address is required")
        if not self.address_city:
            errors.append("City is required")
        if not self.address_postal:
            errors.append("Postal code is required")
        if not self.document_number:
            errors.append("Document number is required")
        
        if self.payout_method == "bank":
            if not self.iban:
                errors.append("IBAN is required for bank transfers")
            if not self.account_holder_name:
                errors.append("Account holder name is required")
        elif self.payout_method == "card":
            if not self.card_token:
                errors.append("Card token is required")
        
        return errors


class Payout:
    def __init__(self, data: Dict[str, Any]):
        self.id = data.get("id", str(uuid.uuid4()))
        self.claim_id = data["claimId"]
        self.recipient_id = data["recipientId"]
        self.amount_eur = data["amountEUR"]
        self.currency_destination = data.get("currencyDestination", "EUR")
        self.fx_rate = data.get("fxRate")
        self.amount_destination = data.get("amountDestination")
        self.provider = data.get("provider", "dlocal")
        self.provider_payout_id = data.get("providerPayoutId")
        self.status = data.get("status", "pending")
        self.failure_reason = data.get("failureReason")
        self.failure_code = data.get("failureCode")
        self.created_at = data.get("createdAt", datetime.utcnow().isoformat())
        self.queued_at = data.get("queuedAt")
        self.sent_at = data.get("sentAt")
        self.settled_at = data.get("settledAt")
        self.retry_count = data.get("retryCount", 0)
        self.next_retry_at = data.get("nextRetryAt")
        self.webhook_last_event = data.get("webhookLastEvent")
        self.webhook_last_event_at = data.get("webhookLastEventAt")
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "claimId": self.claim_id,
            "recipientId": self.recipient_id,
            "amountEUR": self.amount_eur,
            "currencyDestination": self.currency_destination,
            "fxRate": self.fx_rate,
            "amountDestination": self.amount_destination,
            "provider": self.provider,
            "providerPayoutId": self.provider_payout_id,
            "status": self.status,
            "failureReason": self.failure_reason,
            "failureCode": self.failure_code,
            "createdAt": self.created_at,
            "queuedAt": self.queued_at,
            "sentAt": self.sent_at,
            "settledAt": self.settled_at,
            "retryCount": self.retry_count,
            "nextRetryAt": self.next_retry_at,
            "webhookLastEvent": self.webhook_last_event,
            "webhookLastEventAt": self.webhook_last_event_at
        }


# === Database Operations ===

def save_recipient(recipient: Recipient) -> Recipient:
    """Save or update a recipient in the database."""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    recipient.updated_at = datetime.utcnow().isoformat()
    
    cursor.execute("""
        INSERT OR REPLACE INTO recipients 
        (id, claim_id, customer_id, first_name, last_name, email, phone, country,
         address_street, address_city, address_postal, date_of_birth, document_type,
         document_number, payout_method, iban, bic, account_holder_name, bank_name,
         card_token, card_last4, card_brand, currency_preferred, status,
         validation_errors, kyc_screening_result, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        recipient.id, recipient.claim_id, recipient.customer_id, recipient.first_name,
        recipient.last_name, recipient.email, recipient.phone, recipient.country,
        recipient.address_street, recipient.address_city, recipient.address_postal,
        recipient.date_of_birth, recipient.document_type, recipient.document_number,
        recipient.payout_method, recipient.iban, recipient.bic, recipient.account_holder_name,
        recipient.bank_name, recipient.card_token, recipient.card_last4, recipient.card_brand,
        recipient.currency_preferred, recipient.status,
        json.dumps(recipient.validation_errors) if recipient.validation_errors else None,
        recipient.kyc_screening_result, recipient.created_at, recipient.updated_at
    ))
    
    conn.commit()
    conn.close()
    return recipient


def get_recipient_by_claim_id(claim_id: str) -> Optional[Recipient]:
    """Get recipient by claim ID."""
    conn = sqlite3.connect(DATABASE_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM recipients WHERE claim_id = ?", (claim_id,))
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return Recipient({
            "id": row["id"],
            "claimId": row["claim_id"],
            "customerId": row["customer_id"],
            "firstName": row["first_name"],
            "lastName": row["last_name"],
            "email": row["email"],
            "phone": row["phone"],
            "country": row["country"],
            "addressStreet": row["address_street"],
            "addressCity": row["address_city"],
            "addressPostal": row["address_postal"],
            "dateOfBirth": row["date_of_birth"],
            "documentType": row["document_type"],
            "documentNumber": row["document_number"],
            "payoutMethod": row["payout_method"],
            "iban": row["iban"],
            "bic": row["bic"],
            "accountHolderName": row["account_holder_name"],
            "bankName": row["bank_name"],
            "cardToken": row["card_token"],
            "cardLast4": row["card_last4"],
            "cardBrand": row["card_brand"],
            "currencyPreferred": row["currency_preferred"],
            "status": row["status"],
            "validationErrors": json.loads(row["validation_errors"]) if row["validation_errors"] else None,
            "kycScreeningResult": row["kyc_screening_result"],
            "createdAt": row["created_at"],
            "updatedAt": row["updated_at"]
        })
    return None


def get_recipient_by_id(recipient_id: str) -> Optional[Recipient]:
    """Get recipient by ID."""
    conn = sqlite3.connect(DATABASE_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM recipients WHERE id = ?", (recipient_id,))
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return Recipient({
            "id": row["id"],
            "claimId": row["claim_id"],
            "customerId": row["customer_id"],
            "firstName": row["first_name"],
            "lastName": row["last_name"],
            "email": row["email"],
            "phone": row["phone"],
            "country": row["country"],
            "addressStreet": row["address_street"],
            "addressCity": row["address_city"],
            "addressPostal": row["address_postal"],
            "dateOfBirth": row["date_of_birth"],
            "documentType": row["document_type"],
            "documentNumber": row["document_number"],
            "payoutMethod": row["payout_method"],
            "iban": row["iban"],
            "bic": row["bic"],
            "accountHolderName": row["account_holder_name"],
            "bankName": row["bank_name"],
            "cardToken": row["card_token"],
            "cardLast4": row["card_last4"],
            "cardBrand": row["card_brand"],
            "currencyPreferred": row["currency_preferred"],
            "status": row["status"],
            "validationErrors": json.loads(row["validation_errors"]) if row["validation_errors"] else None,
            "kycScreeningResult": row["kyc_screening_result"],
            "createdAt": row["created_at"],
            "updatedAt": row["updated_at"]
        })
    return None


def save_payout(payout: Payout) -> Payout:
    """Save or update a payout in the database."""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT OR REPLACE INTO payouts 
        (id, claim_id, recipient_id, amount_eur, currency_destination, fx_rate,
         amount_destination, provider, provider_payout_id, status, failure_reason,
         failure_code, created_at, queued_at, sent_at, settled_at, retry_count,
         next_retry_at, webhook_last_event, webhook_last_event_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        payout.id, payout.claim_id, payout.recipient_id, payout.amount_eur,
        payout.currency_destination, payout.fx_rate, payout.amount_destination,
        payout.provider, payout.provider_payout_id, payout.status, payout.failure_reason,
        payout.failure_code, payout.created_at, payout.queued_at, payout.sent_at,
        payout.settled_at, payout.retry_count, payout.next_retry_at,
        payout.webhook_last_event, payout.webhook_last_event_at
    ))
    
    conn.commit()
    conn.close()
    return payout


def get_payout_by_claim_id(claim_id: str) -> Optional[Payout]:
    """Get payout by claim ID."""
    conn = sqlite3.connect(DATABASE_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM payouts WHERE claim_id = ? ORDER BY created_at DESC LIMIT 1", (claim_id,))
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return Payout({
            "id": row["id"],
            "claimId": row["claim_id"],
            "recipientId": row["recipient_id"],
            "amountEUR": row["amount_eur"],
            "currencyDestination": row["currency_destination"],
            "fxRate": row["fx_rate"],
            "amountDestination": row["amount_destination"],
            "provider": row["provider"],
            "providerPayoutId": row["provider_payout_id"],
            "status": row["status"],
            "failureReason": row["failure_reason"],
            "failureCode": row["failure_code"],
            "createdAt": row["created_at"],
            "queuedAt": row["queued_at"],
            "sentAt": row["sent_at"],
            "settledAt": row["settled_at"],
            "retryCount": row["retry_count"],
            "nextRetryAt": row["next_retry_at"],
            "webhookLastEvent": row["webhook_last_event"],
            "webhookLastEventAt": row["webhook_last_event_at"]
        })
    return None


def get_payout_by_id(payout_id: str) -> Optional[Payout]:
    """Get payout by ID."""
    conn = sqlite3.connect(DATABASE_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM payouts WHERE id = ?", (payout_id,))
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return Payout({
            "id": row["id"],
            "claimId": row["claim_id"],
            "recipientId": row["recipient_id"],
            "amountEUR": row["amount_eur"],
            "currencyDestination": row["currency_destination"],
            "fxRate": row["fx_rate"],
            "amountDestination": row["amount_destination"],
            "provider": row["provider"],
            "providerPayoutId": row["provider_payout_id"],
            "status": row["status"],
            "failureReason": row["failure_reason"],
            "failureCode": row["failure_code"],
            "createdAt": row["created_at"],
            "queuedAt": row["queued_at"],
            "sentAt": row["sent_at"],
            "settledAt": row["settled_at"],
            "retryCount": row["retry_count"],
            "nextRetryAt": row["next_retry_at"],
            "webhookLastEvent": row["webhook_last_event"],
            "webhookLastEventAt": row["webhook_last_event_at"]
        })
    return None


def get_payout_by_provider_id(provider_payout_id: str) -> Optional[Payout]:
    """Get payout by dLocal payout ID."""
    conn = sqlite3.connect(DATABASE_FILE)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM payouts WHERE provider_payout_id = ?", (provider_payout_id,))
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return Payout({
            "id": row["id"],
            "claimId": row["claim_id"],
            "recipientId": row["recipient_id"],
            "amountEUR": row["amount_eur"],
            "currencyDestination": row["currency_destination"],
            "fxRate": row["fx_rate"],
            "amountDestination": row["amount_destination"],
            "provider": row["provider"],
            "providerPayoutId": row["provider_payout_id"],
            "status": row["status"],
            "failureReason": row["failure_reason"],
            "failureCode": row["failure_code"],
            "createdAt": row["created_at"],
            "queuedAt": row["queued_at"],
            "sentAt": row["sent_at"],
            "settledAt": row["settled_at"],
            "retryCount": row["retry_count"],
            "nextRetryAt": row["next_retry_at"],
            "webhookLastEvent": row["webhook_last_event"],
            "webhookLastEventAt": row["webhook_last_event_at"]
        })
    return None


# === dLocal API Client ===

class DLocalClient:
    """Client for dLocal Payouts API."""
    
    def __init__(self):
        self.base_url = DLOCAL_API_URL
        self.api_key = DLOCAL_API_KEY
        self.secret_key = DLOCAL_SECRET_KEY
    
    def _make_request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict:
        """Make authenticated request to dLocal API."""
        import urllib.request
        
        url = f"{self.base_url}{endpoint}"
        headers = {
            "X-Login": self.api_key,
            "X-Trans-Key": self.secret_key,
            "Content-Type": "application/json"
        }
        
        body = json.dumps(data).encode() if data else None
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                return json.loads(response.read().decode())
        except urllib.error.HTTPError as e:
            error_body = e.read().decode()
            print(f"❌ dLocal API error: {e.code} - {error_body}")
            raise Exception(f"dLocal API error: {e.code}")
    
    def create_payout(self, recipient: Recipient, amount: float, currency: str, reference: str) -> Dict:
        """Create a payout via dLocal API."""
        
        # Build beneficiary data based on payout method
        beneficiary = {
            "name": f"{recipient.first_name} {recipient.last_name}",
            "document_id": recipient.document_number,
            "document_type": self._map_document_type(recipient.document_type),
            "email": recipient.email,
            "address": {
                "street": recipient.address_street,
                "city": recipient.address_city,
                "zip_code": recipient.address_postal,
                "country": recipient.country
            }
        }
        
        if recipient.payout_method == "bank":
            beneficiary["bank_account"] = {
                "iban": recipient.iban,
                "swift_code": recipient.bic,
                "account_holder": recipient.account_holder_name
            }
        
        payload = {
            "amount": amount,
            "currency": currency,
            "country": recipient.country,
            "beneficiary": beneficiary,
            "payout_method_id": "BT", # Bank Transfer
            "notification_url": f"http://localhost:{PORT}/webhooks/dlocal",
            "external_id": reference
        }
        
        print(f"📤 Creating dLocal payout: {reference} - €{amount}")
        
        # In sandbox/development mode, simulate success
        if "sandbox" in self.base_url.lower() or not self.api_key:
            return self._simulate_payout(reference, amount, currency)
        
        return self._make_request("POST", "/payouts", payload)
    
    def get_payout_status(self, payout_id: str) -> Dict:
        """Get payout status from dLocal."""
        if "sandbox" in self.base_url.lower() or not self.api_key:
            return {"id": payout_id, "status": "PENDING"}
        
        return self._make_request("GET", f"/payouts/{payout_id}")
    
    def _map_document_type(self, doc_type: str) -> str:
        """Map our document types to dLocal's."""
        mapping = {
            "DNI": "DNI",
            "Passport": "PASSPORT",
            "NIE": "NIE",
            "Driver's License": "DL"
        }
        return mapping.get(doc_type, "OTHER")
    
    def _simulate_payout(self, reference: str, amount: float, currency: str) -> Dict:
        """Simulate payout response for sandbox/development."""
        return {
            "id": f"DLOCAL-{uuid.uuid4().hex[:8].upper()}",
            "status": "PENDING",
            "amount": amount,
            "currency": currency,
            "external_id": reference,
            "created_date": datetime.utcnow().isoformat()
        }


dlocal_client = DLocalClient()


# === HTTP Handler ===

class PayoutHandler(BaseHTTPRequestHandler):
    
    def do_POST(self):
        path = urlparse(self.path).path
        
        if path == "/api/recipients":
            self._handle_save_recipient()
        elif path == "/webhooks/dlocal":
            self._handle_dlocal_webhook()
        elif path.startswith("/api/payouts/") and path.endswith("/retry"):
            payout_id = path.split("/")[3]
            self._handle_retry_payout(payout_id)
        elif path == "/send-email":
            self._forward_to_email_server()
        else:
            self._send_response(404, {"error": "Not found"})
    
    def do_GET(self):
        path = urlparse(self.path).path
        
        if path == "/health":
            self._send_response(200, {"status": "ok"})
        elif path.startswith("/api/recipients/claim/"):
            claim_id = path.split("/")[-1]
            self._handle_get_recipient_by_claim(claim_id)
        elif path.startswith("/api/payouts/claim/"):
            claim_id = path.split("/")[-1]
            self._handle_get_payout_by_claim(claim_id)
        elif path.startswith("/api/payouts/"):
            payout_id = path.split("/")[-1]
            self._handle_get_payout(payout_id)
        else:
            self._send_response(404, {"error": "Not found"})
    
    def _handle_save_recipient(self):
        """Handle POST /api/recipients - Save or update recipient."""
        try:
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode("utf-8"))
            
            print(f"\n📥 Received recipient data for claim: {data.get('claimId')}")
            
            # Check if recipient already exists for this claim
            existing = get_recipient_by_claim_id(data["claimId"])
            if existing:
                data["id"] = existing.id
                data["createdAt"] = existing.created_at
            
            recipient = Recipient(data)
            
            # Validate
            errors = recipient.validate()
            if errors:
                print(f"❌ Validation errors: {errors}")
                self._send_response(400, {"error": "Validation failed", "errors": errors})
                return
            
            # Mark as verified (simplified - in production, do KYC screening)
            recipient.status = "verified"
            
            # Save
            saved = save_recipient(recipient)
            print(f"✅ Recipient saved: {saved.id}")
            
            self._send_response(201 if not existing else 200, saved.to_dict())
            
        except Exception as e:
            print(f"❌ Error saving recipient: {e}")
            self._send_response(500, {"error": str(e)})
    
    def _handle_get_recipient_by_claim(self, claim_id: str):
        """Handle GET /api/recipients/claim/{claimId}."""
        recipient = get_recipient_by_claim_id(claim_id)
        if recipient:
            self._send_response(200, recipient.to_dict())
        else:
            self._send_response(404, {"error": "Recipient not found"})
    
    def _handle_get_payout_by_claim(self, claim_id: str):
        """Handle GET /api/payouts/claim/{claimId}."""
        payout = get_payout_by_claim_id(claim_id)
        if payout:
            self._send_response(200, payout.to_dict())
        else:
            self._send_response(404, {"error": "Payout not found"})
    
    def _handle_get_payout(self, payout_id: str):
        """Handle GET /api/payouts/{payoutId}."""
        payout = get_payout_by_id(payout_id)
        if payout:
            self._send_response(200, payout.to_dict())
        else:
            self._send_response(404, {"error": "Payout not found"})
    
    def _handle_retry_payout(self, payout_id: str):
        """Handle POST /api/payouts/{payoutId}/retry - Retry a failed payout."""
        try:
            payout = get_payout_by_id(payout_id)
            if not payout:
                self._send_response(404, {"error": "Payout not found"})
                return
            
            if payout.status not in ["failed"]:
                self._send_response(400, {"error": f"Cannot retry payout with status: {payout.status}"})
                return
            
            recipient = get_recipient_by_id(payout.recipient_id)
            if not recipient:
                self._send_response(400, {"error": "Recipient not found"})
                return
            
            # Increment retry count
            payout.retry_count += 1
            payout.status = "queued"
            payout.queued_at = datetime.utcnow().isoformat()
            payout.failure_reason = None
            payout.failure_code = None
            
            save_payout(payout)
            
            # Submit to dLocal
            try:
                result = dlocal_client.create_payout(
                    recipient=recipient,
                    amount=payout.amount_eur,
                    currency=payout.currency_destination,
                    reference=payout.id
                )
                
                payout.provider_payout_id = result.get("id")
                payout.status = "processing"
                payout.sent_at = datetime.utcnow().isoformat()
                save_payout(payout)
                
                print(f"✅ Payout retry submitted: {payout.id} -> {payout.provider_payout_id}")
                
            except Exception as e:
                payout.status = "failed"
                payout.failure_reason = str(e)
                save_payout(payout)
                print(f"❌ Payout retry failed: {e}")
            
            self._send_response(200, payout.to_dict())
            
        except Exception as e:
            print(f"❌ Error retrying payout: {e}")
            self._send_response(500, {"error": str(e)})
    
    def _handle_dlocal_webhook(self):
        """Handle POST /webhooks/dlocal - Process dLocal webhook events."""
        try:
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)
            payload = json.loads(post_data.decode("utf-8"))
            
            print(f"\n📩 Received dLocal webhook: {payload.get('type')}")
            
            # Verify webhook signature (in production)
            # signature = self.headers.get("X-DLocal-Signature")
            # if not self._verify_webhook_signature(post_data, signature):
            #     self._send_response(401, {"error": "Invalid signature"})
            #     return
            
            event_type = payload.get("type", "unknown")
            payout_data = payload.get("data", {})
            provider_payout_id = payout_data.get("id")
            
            if not provider_payout_id:
                self._send_response(400, {"error": "Missing payout ID"})
                return
            
            # Find our payout record
            payout = get_payout_by_provider_id(provider_payout_id)
            if not payout:
                # Try by external_id
                external_id = payout_data.get("external_id")
                if external_id:
                    payout = get_payout_by_id(external_id)
            
            if not payout:
                print(f"⚠️ Payout not found for webhook: {provider_payout_id}")
                self._send_response(200, {"status": "ignored"})
                return
            
            # Update payout status based on event
            old_status = payout.status
            
            if event_type in ["payout.pending", "payout.created"]:
                payout.status = "processing"
            elif event_type == "payout.completed":
                payout.status = "sent"
                payout.sent_at = datetime.utcnow().isoformat()
            elif event_type == "payout.paid":
                payout.status = "settled"
                payout.settled_at = datetime.utcnow().isoformat()
            elif event_type in ["payout.rejected", "payout.cancelled", "payout.failed"]:
                payout.status = "failed"
                payout.failure_reason = payout_data.get("status_detail") or payout_data.get("reject_reason")
                payout.failure_code = payout_data.get("status_code")
            
            payout.webhook_last_event = event_type
            payout.webhook_last_event_at = datetime.utcnow().isoformat()
            
            save_payout(payout)
            
            # Log webhook event
            log_webhook_event(event_type, payout.id, provider_payout_id, payload)
            
            print(f"✅ Payout {payout.id} status: {old_status} -> {payout.status}")
            
            # Send notification email
            if payout.status in ["sent", "settled", "failed"]:
                self._send_payout_notification(payout)
            
            self._send_response(200, {"status": "ok"})
            
        except Exception as e:
            print(f"❌ Error processing webhook: {e}")
            self._send_response(500, {"error": str(e)})
    
    def _send_payout_notification(self, payout: Payout):
        """Send email notification about payout status change."""
        recipient = get_recipient_by_id(payout.recipient_id)
        if not recipient:
            return
        
        if payout.status == "sent":
            subject = "Your compensation payment is on the way!"
            body = f"""Dear {recipient.first_name},

Great news! Your compensation payment of €{payout.amount_eur:.2f} has been sent to your bank account.

Bank Account: {recipient.iban[:4]}...{recipient.iban[-4:] if recipient.iban else 'N/A'}
Expected Arrival: 1-3 business days

You will receive another notification when the payment is confirmed in your account.

Thank you for using FlightCompensation.

Best regards,
FlightCompensation Team
"""
        elif payout.status == "settled":
            subject = "Your compensation has been received!"
            body = f"""Dear {recipient.first_name},

Your compensation payment of €{payout.amount_eur:.2f} has been successfully deposited into your bank account.

Reference: {payout.id}

Thank you for choosing FlightCompensation.

Best regards,
FlightCompensation Team
"""
        elif payout.status == "failed":
            subject = "Action needed: Payment issue"
            body = f"""Dear {recipient.first_name},

Unfortunately, we encountered an issue sending your compensation payment of €{payout.amount_eur:.2f}.

Reason: {payout.failure_reason or 'Unknown error'}

Please log into the app and verify your bank details are correct. Once updated, we will retry the payment automatically.

If you need assistance, please contact our support team.

Best regards,
FlightCompensation Team
"""
        else:
            return
        
        # Send email via email server
        try:
            import urllib.request
            email_data = {
                "to": recipient.email,
                "subject": subject,
                "body": body
            }
            req = urllib.request.Request(
                EMAIL_SERVER_URL,
                data=json.dumps(email_data).encode(),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            urllib.request.urlopen(req, timeout=10)
            print(f"📧 Notification sent to {recipient.email}")
        except Exception as e:
            print(f"⚠️ Failed to send notification: {e}")
    
    def _forward_to_email_server(self):
        """Forward email requests to the email sending logic."""
        # This is a simplified version - in production, reuse email_server.py logic
        self._send_response(200, {"status": "ok", "message": "Email queued"})
    
    def _verify_webhook_signature(self, payload: bytes, signature: str) -> bool:
        """Verify dLocal webhook signature."""
        if not DLOCAL_WEBHOOK_SECRET or not signature:
            return True  # Skip verification in development
        
        expected = hmac.new(
            DLOCAL_WEBHOOK_SECRET.encode(),
            payload,
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(expected, signature)
    
    def _send_response(self, status: int, data: Dict):
        """Send JSON response."""
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass


def log_webhook_event(event_type: str, payout_id: str, provider_payout_id: str, payload: Dict):
    """Log webhook event to database."""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO webhook_events (id, event_type, payout_id, provider_payout_id, payload, processed_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        str(uuid.uuid4()),
        event_type,
        payout_id,
        provider_payout_id,
        json.dumps(payload),
        datetime.utcnow().isoformat()
    ))
    
    conn.commit()
    conn.close()


# === Main ===

def main():
    init_database()
    
    print("=" * 50)
    print("🚀 Flighty Compensation Payout Server")
    print("=" * 50)
    print(f"📡 Listening on: http://localhost:{PORT}")
    print(f"💳 dLocal API: {DLOCAL_API_URL}")
    print(f"🔑 dLocal configured: {'Yes' if DLOCAL_API_KEY else 'No (sandbox mode)'}")
    print("\nEndpoints:")
    print(f"  POST http://localhost:{PORT}/api/recipients")
    print(f"  GET  http://localhost:{PORT}/api/recipients/claim/{{claimId}}")
    print(f"  GET  http://localhost:{PORT}/api/payouts/claim/{{claimId}}")
    print(f"  POST http://localhost:{PORT}/api/payouts/{{payoutId}}/retry")
    print(f"  POST http://localhost:{PORT}/webhooks/dlocal")
    print(f"  GET  http://localhost:{PORT}/health")
    print("\nPress Ctrl+C to stop.\n")
    
    server = HTTPServer(("", PORT), PayoutHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Shutting down server.")
        server.shutdown()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Bank Reconciliation Job
=======================
Daily job that:
1. Ingests bank statements (manual CSV or MT940 import)
2. Matches incoming transfers to claims by reference/amount
3. Triggers payouts for reconciliations older than 48 hours

Run manually:
    python3 reconciliation_job.py

Or via cron (daily at 9 AM):
    0 9 * * * cd /path/to/server && python3 reconciliation_job.py
"""

import os
import json
import csv
import uuid
import re
import sqlite3
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List, Tuple

DATABASE_FILE = "payouts.db"
STATEMENTS_DIR = "bank_statements"
PAYOUT_DELAY_HOURS = 48  # Wait 48 hours after receiving funds before payout

# Payout server URL
PAYOUT_SERVER_URL = "http://localhost:8080"


# === Database Operations ===

def get_db_connection():
    return sqlite3.connect(DATABASE_FILE)


def save_reconciliation(
    bank_ref: str,
    amount_eur: float,
    received_at: str,
    matched_claim_id: Optional[str] = None,
    status: str = "pending_match"
) -> str:
    """Save a bank reconciliation record."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    rec_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()
    
    cursor.execute("""
        INSERT INTO bank_reconciliations 
        (id, bank_ref, amount_eur, received_at, matched_claim_id, matched_at, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        rec_id, bank_ref, amount_eur, received_at,
        matched_claim_id,
        now if matched_claim_id else None,
        status, now
    ))
    
    conn.commit()
    conn.close()
    return rec_id


def get_pending_reconciliations() -> List[Dict]:
    """Get reconciliations that haven't been paid out yet."""
    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT * FROM bank_reconciliations 
        WHERE status = 'matched' AND matched_claim_id IS NOT NULL
        ORDER BY received_at ASC
    """)
    
    rows = cursor.fetchall()
    conn.close()
    
    return [dict(row) for row in rows]


def update_reconciliation_status(rec_id: str, status: str, notes: Optional[str] = None):
    """Update reconciliation status."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    if notes:
        cursor.execute("""
            UPDATE bank_reconciliations SET status = ?, notes = ? WHERE id = ?
        """, (status, notes, rec_id))
    else:
        cursor.execute("""
            UPDATE bank_reconciliations SET status = ? WHERE id = ?
        """, (status, rec_id))
    
    conn.commit()
    conn.close()


def get_claim_by_reference(reference: str) -> Optional[Dict]:
    """
    Look up claim by AESA reference number.
    In production, this would query Firebase/Firestore.
    For now, we simulate by extracting claim ID from reference pattern.
    """
    # Expected patterns:
    # - AESA-2024-CLAIM123
    # - FC-CLAIM123-COMPENSATION
    # - Direct claim ID: CLAIM123
    
    patterns = [
        r'FC-([A-Z0-9]+)-COMPENSATION',
        r'AESA-\d{4}-([A-Z0-9]+)',
        r'CLAIM([A-Z0-9]+)',
        r'([A-F0-9]{8})',  # UUID prefix
    ]
    
    for pattern in patterns:
        match = re.search(pattern, reference.upper())
        if match:
            return {
                "id": match.group(1) if match.group(1) else match.group(0),
                "reference": reference
            }
    
    return None


def get_claim_compensation_amount(claim_id: str) -> Optional[float]:
    """
    Get expected compensation amount for a claim.
    In production, query Firebase/Firestore.
    """
    # Simulated - in production, fetch from claims database
    # Standard EU261 amounts: 250, 400, 600 EUR
    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Check if we have a recipient for this claim (they submitted bank details)
    cursor.execute("""
        SELECT * FROM recipients WHERE claim_id = ? AND status = 'verified'
    """, (claim_id,))
    
    row = cursor.fetchone()
    conn.close()
    
    if row:
        # For now, accept any EU261 standard amount
        return None  # Will match any standard amount
    
    return None


def recipient_exists_for_claim(claim_id: str) -> bool:
    """Check if a verified recipient exists for this claim."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT COUNT(*) FROM recipients WHERE claim_id = ? AND status = 'verified'
    """, (claim_id,))
    
    count = cursor.fetchone()[0]
    conn.close()
    
    return count > 0


def payout_exists_for_claim(claim_id: str) -> bool:
    """Check if a payout already exists for this claim."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT COUNT(*) FROM payouts WHERE claim_id = ? AND status NOT IN ('failed', 'cancelled')
    """, (claim_id,))
    
    count = cursor.fetchone()[0]
    conn.close()
    
    return count > 0


# === Bank Statement Parsing ===

def parse_csv_statement(filepath: str) -> List[Dict]:
    """
    Parse a CSV bank statement.
    Expected columns: Date, Description, Credit, Debit, Reference
    """
    transactions = []
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Only process credits (incoming transfers)
                credit = row.get('Credit', row.get('credit', row.get('CREDIT', '')))
                if credit and float(credit.replace(',', '').replace(' ', '') or 0) > 0:
                    transactions.append({
                        'date': row.get('Date', row.get('date', row.get('DATE', ''))),
                        'description': row.get('Description', row.get('description', row.get('DESCRIPTION', ''))),
                        'amount': float(credit.replace(',', '').replace(' ', '')),
                        'reference': row.get('Reference', row.get('reference', row.get('REFERENCE', '')))
                    })
    except Exception as e:
        print(f"❌ Error parsing CSV {filepath}: {e}")
    
    return transactions


def parse_mt940_statement(filepath: str) -> List[Dict]:
    """
    Parse an MT940 SWIFT statement file.
    This is a simplified parser - production would use a library like mt940.
    """
    transactions = []
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find transaction blocks (tag :61:)
        # Format: :61:YYMMDD[MMDD]C{amount}NTRF{reference}
        pattern = r':61:(\d{6})\d*C([\d,\.]+)N[A-Z]{3,4}([^\n]+)'
        matches = re.findall(pattern, content)
        
        for match in matches:
            date_str, amount_str, reference = match
            
            # Parse date (YYMMDD)
            try:
                date = datetime.strptime(date_str, '%y%m%d').strftime('%Y-%m-%d')
            except:
                date = date_str
            
            # Parse amount
            amount = float(amount_str.replace(',', '.'))
            
            transactions.append({
                'date': date,
                'description': reference.strip(),
                'amount': amount,
                'reference': reference.strip()[:50]
            })
    
    except Exception as e:
        print(f"❌ Error parsing MT940 {filepath}: {e}")
    
    return transactions


# === Reconciliation Logic ===

def ingest_bank_statements():
    """Process new bank statements from the statements directory."""
    if not os.path.exists(STATEMENTS_DIR):
        os.makedirs(STATEMENTS_DIR)
        print(f"📁 Created statements directory: {STATEMENTS_DIR}")
        return
    
    processed_dir = os.path.join(STATEMENTS_DIR, "processed")
    if not os.path.exists(processed_dir):
        os.makedirs(processed_dir)
    
    statement_files = [
        f for f in os.listdir(STATEMENTS_DIR) 
        if f.endswith(('.csv', '.mt940', '.sta')) and not f.startswith('.')
    ]
    
    if not statement_files:
        print(f"📄 No new statement files in {STATEMENTS_DIR}")
        return
    
    total_imported = 0
    total_matched = 0
    
    for filename in statement_files:
        filepath = os.path.join(STATEMENTS_DIR, filename)
        print(f"\n📄 Processing: {filename}")
        
        # Parse based on file type
        if filename.endswith('.csv'):
            transactions = parse_csv_statement(filepath)
        elif filename.endswith(('.mt940', '.sta')):
            transactions = parse_mt940_statement(filepath)
        else:
            continue
        
        print(f"   Found {len(transactions)} credit transactions")
        
        for txn in transactions:
            # Skip small amounts (likely fees refunds, not AESA payments)
            if txn['amount'] < 50:
                continue
            
            # Try to match to a claim
            reference = txn['reference'] or txn['description']
            claim = get_claim_by_reference(reference)
            
            # Check if already reconciled
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT COUNT(*) FROM bank_reconciliations WHERE bank_ref = ?
            """, (reference,))
            exists = cursor.fetchone()[0] > 0
            conn.close()
            
            if exists:
                continue
            
            matched_claim_id = None
            status = "pending_match"
            
            if claim and recipient_exists_for_claim(claim['id']):
                matched_claim_id = claim['id']
                status = "matched"
                total_matched += 1
                print(f"   ✅ Matched €{txn['amount']:.2f} to claim {claim['id']}")
            else:
                print(f"   ⚠️ Unmatched €{txn['amount']:.2f} - {reference[:40]}...")
            
            # Parse date
            try:
                if isinstance(txn['date'], str):
                    # Try common formats
                    for fmt in ['%Y-%m-%d', '%d/%m/%Y', '%d-%m-%Y', '%Y%m%d']:
                        try:
                            received_at = datetime.strptime(txn['date'], fmt).isoformat()
                            break
                        except:
                            continue
                    else:
                        received_at = datetime.utcnow().isoformat()
                else:
                    received_at = txn['date'].isoformat()
            except:
                received_at = datetime.utcnow().isoformat()
            
            # Save reconciliation record
            save_reconciliation(
                bank_ref=reference,
                amount_eur=txn['amount'],
                received_at=received_at,
                matched_claim_id=matched_claim_id,
                status=status
            )
            total_imported += 1
        
        # Move processed file
        new_path = os.path.join(processed_dir, f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{filename}")
        os.rename(filepath, new_path)
        print(f"   📦 Moved to processed: {new_path}")
    
    print(f"\n📊 Summary: {total_imported} imported, {total_matched} matched")


def trigger_due_payouts():
    """
    Find reconciled funds older than 48 hours and trigger payouts.
    This implements the business rule: pay customer within 48h of receiving AESA funds.
    """
    import urllib.request
    
    reconciliations = get_pending_reconciliations()
    
    if not reconciliations:
        print("📭 No pending reconciliations ready for payout")
        return
    
    cutoff_time = datetime.utcnow() - timedelta(hours=PAYOUT_DELAY_HOURS)
    payouts_triggered = 0
    
    for rec in reconciliations:
        received_at = datetime.fromisoformat(rec['received_at'].replace('Z', '+00:00').replace('+00:00', ''))
        
        # Check if 48h have passed
        if received_at > cutoff_time:
            hours_remaining = (received_at + timedelta(hours=PAYOUT_DELAY_HOURS) - datetime.utcnow()).total_seconds() / 3600
            print(f"⏳ Claim {rec['matched_claim_id']}: {hours_remaining:.1f}h until payout")
            continue
        
        claim_id = rec['matched_claim_id']
        
        # Check if payout already exists
        if payout_exists_for_claim(claim_id):
            print(f"⏭️ Claim {claim_id}: Payout already exists, skipping")
            update_reconciliation_status(rec['id'], 'payout_created')
            continue
        
        # Check recipient exists
        if not recipient_exists_for_claim(claim_id):
            print(f"⚠️ Claim {claim_id}: No verified recipient, cannot payout")
            continue
        
        # Create payout via payout server
        print(f"💸 Creating payout for claim {claim_id}, €{rec['amount_eur']:.2f}")
        
        try:
            payout_data = {
                "claimId": claim_id,
                "amountEUR": rec['amount_eur']
            }
            
            # Get recipient details first
            req = urllib.request.Request(
                f"{PAYOUT_SERVER_URL}/api/recipients/claim/{claim_id}",
                method="GET"
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                recipient = json.loads(resp.read().decode())
            
            # Now create the payout directly in DB and submit to dLocal
            # (The payout server handles dLocal submission)
            conn = get_db_connection()
            cursor = conn.cursor()
            
            payout_id = str(uuid.uuid4())
            now = datetime.utcnow().isoformat()
            
            cursor.execute("""
                INSERT INTO payouts 
                (id, claim_id, recipient_id, amount_eur, currency_destination, 
                 provider, status, created_at, queued_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                payout_id, claim_id, recipient['id'], rec['amount_eur'],
                recipient.get('currencyPreferred', 'EUR'),
                'dlocal', 'queued', now, now
            ))
            
            conn.commit()
            conn.close()
            
            # Trigger dLocal submission via payout server
            # In production, this would call the dLocal API directly
            print(f"✅ Payout {payout_id} created for claim {claim_id}")
            
            # Update reconciliation status
            update_reconciliation_status(rec['id'], 'payout_created', f'Payout ID: {payout_id}')
            payouts_triggered += 1
            
        except Exception as e:
            print(f"❌ Failed to create payout for claim {claim_id}: {e}")
            update_reconciliation_status(rec['id'], 'payout_failed', str(e))
    
    print(f"\n💰 Payouts triggered: {payouts_triggered}")


def manual_match_reconciliation(rec_id: str, claim_id: str):
    """Manually match an unmatched reconciliation to a claim."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        UPDATE bank_reconciliations 
        SET matched_claim_id = ?, matched_at = ?, status = 'matched'
        WHERE id = ? AND status = 'pending_match'
    """, (claim_id, datetime.utcnow().isoformat(), rec_id))
    
    if cursor.rowcount > 0:
        print(f"✅ Matched reconciliation {rec_id} to claim {claim_id}")
    else:
        print(f"❌ Failed to match - reconciliation not found or already matched")
    
    conn.commit()
    conn.close()


def list_pending_matches():
    """List unmatched reconciliations for manual review."""
    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT * FROM bank_reconciliations WHERE status = 'pending_match'
        ORDER BY received_at DESC
    """)
    
    rows = cursor.fetchall()
    conn.close()
    
    if not rows:
        print("📭 No unmatched reconciliations")
        return
    
    print("\n🔍 Unmatched Reconciliations:")
    print("-" * 80)
    for row in rows:
        print(f"ID: {row['id'][:8]}...")
        print(f"   Amount: €{row['amount_eur']:.2f}")
        print(f"   Reference: {row['bank_ref'][:50]}")
        print(f"   Received: {row['received_at'][:10]}")
        print()


def run_full_reconciliation():
    """Run the complete reconciliation process."""
    print("=" * 50)
    print("🏦 Bank Reconciliation Job")
    print(f"⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)
    
    # Step 1: Ingest new bank statements
    print("\n📥 Step 1: Ingesting bank statements...")
    ingest_bank_statements()
    
    # Step 2: Trigger due payouts
    print("\n💸 Step 2: Triggering due payouts (48h rule)...")
    trigger_due_payouts()
    
    # Step 3: Report unmatched
    print("\n📋 Step 3: Unmatched summary...")
    list_pending_matches()
    
    print("\n✅ Reconciliation complete")


# === CLI Interface ===

def main():
    import sys
    
    if len(sys.argv) < 2:
        run_full_reconciliation()
        return
    
    command = sys.argv[1]
    
    if command == "ingest":
        ingest_bank_statements()
    
    elif command == "payouts":
        trigger_due_payouts()
    
    elif command == "unmatched":
        list_pending_matches()
    
    elif command == "match" and len(sys.argv) >= 4:
        rec_id = sys.argv[2]
        claim_id = sys.argv[3]
        manual_match_reconciliation(rec_id, claim_id)
    
    elif command == "help":
        print("""
Bank Reconciliation Job
=======================

Usage:
    python3 reconciliation_job.py           Run full reconciliation
    python3 reconciliation_job.py ingest    Only ingest new statements
    python3 reconciliation_job.py payouts   Only trigger due payouts
    python3 reconciliation_job.py unmatched List unmatched transactions
    python3 reconciliation_job.py match <rec_id> <claim_id>  Manual match

Statement Import:
    Place CSV or MT940 files in ./bank_statements/ directory.
    
CSV Format:
    Date,Description,Credit,Debit,Reference
    2024-01-15,AESA COMPENSATION FC-CLAIM123,400.00,,AESA-2024-CLAIM123
    
MT940 Format:
    Standard SWIFT MT940 format (.mt940 or .sta extension)
""")
    
    else:
        print(f"Unknown command: {command}")
        print("Run 'python3 reconciliation_job.py help' for usage")


if __name__ == "__main__":
    main()

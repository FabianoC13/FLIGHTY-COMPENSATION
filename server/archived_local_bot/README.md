# Archived Local Email Bot

This directory contains the local Python email bot that was previously used to send emails via file system monitoring.

**Archived on:** 2026-01-21  
**Reason:** Migrated to cloud-based Firebase "Trigger Email from Firestore" extension

## Files Archived

- `email_bot.py` - Local file system watcher that sent emails via Gmail SMTP
- `.env` - Environment variables with Gmail credentials

## Migration Notes

The app now uses:
- **EmailService.swift** writes to Firestore `mail` collection
- **Firebase Extension** "Trigger Email from Firestore" watches `mail` collection and sends emails automatically
- **No local dependencies** - everything runs in the cloud

## Restoration (if needed)

If you need to restore the local email bot for any reason:

```bash
cd /Users/fabiano/Documents/FLIGHTY\ COMPENSATION/server
mv archived_local_bot/email_bot.py .
mv archived_local_bot/.env .
python3 email_bot.py
```

## Credentials

- Gmail: pepegallardo69420@gmail.com
- App Password (OLD): enme cwlr ctro jnjy (in .env)
- App Password (NEW): ijte aoch bvgl ywfw (configured in Firebase Extension)

# Firebase Email Extension Setup Guide

## Quick Setup Instructions

Follow these steps to complete the cloud email migration:

### 1. Install Firebase Extension

1. Open [Firebase Console - Extensions](https://console.firebase.google.com/project/flighty-61f56/extensions)
2. Click **"Install Extension"**
3. Search for **"Trigger Email from Firestore"** (official Firebase extension)
4. Click **"Install in console"**

### 2. Configure Extension

When prompted, enter these values:

| Setting | Value |
|---------|-------|
| **Collection path** | `mail` |
| **SMTP connection URI** | `smtps://pepegallardo69420@gmail.com:ijteoachbvglywfw@smtp.gmail.com:465` |
| **Default FROM address** | `pepegallardo69420@gmail.com` |
| **Default REPLY-TO address** | `pepegallardo69420@gmail.com` |
| **Email documents collection** | `mail` |

### 3. Deploy

Click **"Install Extension"** and wait for deployment to complete (~2-3 minutes).

---

## Verification

After installation:

1. **Run your iOS app** and submit a test claim
2. **Open Firebase Console** → **Firestore Database** → **`mail` collection**
3. **Check document** - Status should change from `PENDING` to `SUCCESS`
4. **Check your Gmail inbox** for the test email

---

## Architecture Overview

```
iOS App (EmailService.swift)
    ↓
Firestore ('mail' collection)
    ↓
Firebase Extension (auto-triggered)
    ↓
Gmail SMTP
    ↓
Email delivered ✅
```

---

## Troubleshooting

### Extension not sending emails?

1. Check Extension logs: **Firebase Console → Extensions → Trigger Email → Logs**
2. Verify SMTP URI is correct (no typos in password)
3. Ensure Gmail App Password is still active

### Email document stuck in PENDING?

- The extension may not be installed correctly
- Check Firebase Functions logs for errors

---

## Credentials Reference

- **Gmail Account**: `pepegallardo69420@gmail.com`
- **App Password**: `ijte aoch bvgl ywfw` (generated 2026-01-21)
- **SMTP URI Format**: `smtps://[email]:[app-password]@smtp.gmail.com:465`

---

## What Changed?

✅ **Removed**: Local Python email bot (`email_bot.py`)  
✅ **Disabled**: Custom Cloud Function (`onClaimCreated`)  
✅ **Added**: Firebase Extension for email sending  
✅ **No changes needed**: iOS app (`EmailService.swift`) already cloud-ready!

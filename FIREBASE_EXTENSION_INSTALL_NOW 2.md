# Quick Firebase Extension Installation Guide

I've prepared everything for you - just follow these simple steps in your browser!

## Installation Steps

You already have the Firebase Console open! Here's what to do:

### 1. Navigate to Extension Installation

You should see one of these pages already open:
- [Firebase Extensions Install Page](https://console.firebase.google.com/project/flighty-61f56/extensions/install?ref...)

If not, go to: https://console.firebase.google.com/project/flighty-61f56/extensions

### 2. Install "Trigger Email from Firestore"

- Click **"Install Extension"** or search for "Trigger Email from Firestore"
- Select the **official Firebase extension** (by Firebase)
- Click **"Install in console"**

### 3. Fill in Configuration

Copy and paste these exact values:

| Field | Value |
|-------|-------|
| **Collection path** | `mail` |
| **SMTP connection URI** | `smtps://fabianocalvaye@gmail.com:ijteoachbvglywfw@smtp.gmail.com:465` |
| **Default FROM address** | `fabianocalvaye@gmail.com` |
| **Default REPLY-TO address** | `fabianocalvaye@gmail.com` |

> **IMPORTANT:** Copy the SMTP URI exactly as shown - don't add spaces!

### 4. Complete Installation

- Review the configuration
- Click **"Install Extension"**
- Wait ~2-3 minutes for deployment

### 5. Verify Installation

After deployment completes:
1. Go to **Extensions** tab in Firebase Console
2. You should see "Trigger Email from Firestore" with status **"Active"**

---

## Quick Copy-Paste

**SMTP URI (copy this):**
```
smtps://fabianocalvaye@gmail.com:ijteoachbvglywfw@smtp.gmail.com:465
```

**Collection path:**
```
mail
```

**FROM and REPLY-TO:**
```
fabianocalvaye@gmail.com
```

---

## What Happens After Installation?

Your iOS app will automatically start sending emails through Firebase! No code changes needed.

**Test it:**
1. Run your iOS app
2. Submit a test claim
3. Check Firestore → `mail` collection
4. Email should arrive in Gmail inbox within seconds!

---

## Need Help?

If you see any errors during installation, check:
- ✅ Firebase project is on **Blaze (pay-as-you-go)** plan
- ✅ SMTP URI has no extra spaces or typos
- ✅ Gmail App Password is still active

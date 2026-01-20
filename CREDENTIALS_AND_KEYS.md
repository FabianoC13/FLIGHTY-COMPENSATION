
# Credentials and API Keys (Flighty Compensation)

This document lists the API keys and credentials specifically required for the **Flighty Compensation** project.

## 1. Google / Firebase (Project: `flighty-61f56`)

**Source:** `FlightCompensation/GoogleService-Info.plist`
These are the public identifiers used by the iOS application.

*   **Project ID:** `flighty-61f56`
*   **API Key:** `AIzaSyAi1FhHIUqvs2wVKOc0KTqdUq07_9H72ng`
*   **Google App ID:** `1:1091915389454:ios:2b0b1e12a527e13c58ba5f`
*   **GCM Sender ID:** `1091915389454`
*   **Client ID:** `1091915389454-p26vcjmskod2d7s768qq2i48q5f4dooe.apps.googleusercontent.com`
*   **Reversed Client ID:** `com.googleusercontent.apps.1091915389454-p26vcjmskod2d7s768qq2i48q5f4dooe`

## 2. Email Automation (Gmail)

**Source:** `FlightCompensation/functions/index.js`
Used by the Firebase Cloud Functions to send transactional emails (complaints, confirmations).

*   **Service:** Gmail
*   **User:** `pepegallardo69420@gmail.com`
*   **App Password:** `enme cwlr ctro jnjy`

## 3. Flight Data (FlightRadar24)

**Source:** `FlightCompensation/Utilities/Config.swift`
Required for live flight tracking data.

*   **Configuration:** The app looks for an environment variable named `FLIGHT_RADAR24_API_KEY`.
*   **Current State:** Defaults to a placeholder. You must set this environment variable for the app to fetch live data.

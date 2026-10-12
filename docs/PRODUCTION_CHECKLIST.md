# Production checklist

## Keys and settings to provide

| What | Where | Used for |
|---|---|---|
| FlightRadar24 API key (`id|secret`) | `Config/Secrets.xcconfig` → `FLIGHT_RADAR24_API_KEY` | Live flight status and measured arrival delays |
| FlightRadar24 sandbox flag | `Config/Secrets.xcconfig` → `FLIGHT_RADAR24_SANDBOX = YES` | Only when using a sandbox key; it is no longer guessed from the key |
| Company legal name, tax ID, address, email | `Config/Secrets.xcconfig` → `COMPANY_*` | Named in every document passengers sign. Release builds refuse to submit claims until set |
| Client-money IBAN / BIC | `COLLECTION_IBAN`, `COLLECTION_BIC` | Printed in the airline letter as the payment account |
| Terms and privacy URLs | `TERMS_URL`, `PRIVACY_URL` | Linked from the agreement |
| Fee | `SUCCESS_FEE_PERCENT`, `LEGAL_ACTION_FEE_PERCENT` | Shown before signing and written into the agreement |
| Ops inbox and company name for emails | `FlightCompensation/functions/.env.<project>` → `OPS_EMAIL`, `COMPANY_NAME` | Cloud Function emails |
| Firebase "Trigger Email" extension + SMTP credentials | Firebase console | Sends everything queued in the `mail` collection |
| dLocal API key, secret key, webhook secret | `server/.env` | Payouts to passengers |
| `PAYOUT_API_TOKEN`, `EMAIL_SERVER_TOKEN` | `server/.env` | Auth between back-office tools and the payout/email servers |
| Gmail/SMTP for `email_server.py` | `server/.env` | Payout notification emails |

## Before launch

- [ ] **Rotate the FlightRadar24 key.** The previous key and secret were committed in old docs and are in git history.
- [ ] Have a lawyer review `FlightCompensation/Services/ClaimAgreementText.swift` (agreement, assignment, power of attorney, guardian declaration). Bump `ClaimDocumentVersion.current` on every change.
- [ ] Register the company for debt-collection / legal-services activity where required (e.g. RDG registration in Germany).
- [ ] Verify the airline inboxes in `functions/airlines.js`; keep web-form-only airlines in `WEB_FORM_ONLY`.
- [ ] Deploy rules and functions: `cd FlightCompensation/functions && npm run deploy`.
- [ ] Install the Firebase Trigger Email extension pointing at the `mail` collection.
- [ ] Run `payout_server.py` behind HTTPS with `PUBLIC_BASE_URL` set; confirm the dLocal webhook signature format against dLocal's current docs (`verify_dlocal_signature`).
- [ ] Release build settings: signing team, version/build numbers, App Store privacy answers matching `PrivacyInfo.xcprivacy`.
- [ ] Translate the in-app agreement and airline letter if you file in languages other than English.

## Known limits

- Claims are per passenger. Each adult co-passenger files from their own account; a parent or guardian can claim for a child.
- Connecting flights are assessed leg by leg; EU261 measures delay at the final destination of the booking.
- The FlightRadar24 key ships inside the app. Moving flight lookups behind a Cloud Function would keep it server-side.
- Measured delays come from flight data when the API returns an actual arrival time; otherwise the passenger's answer is used and ops should verify it.

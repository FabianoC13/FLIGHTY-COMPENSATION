# Flight Compensation

iOS app (SwiftUI, iOS 17+) that tracks flights and files EU261 / UK261 compensation claims
for passengers, with a Firebase backend and a Python payout service.

## Repository layout

| Path | What it is |
|---|---|
| `FlightCompensation/` | iOS app sources (`FlightCompensation.xcodeproj`, or regenerate with XcodeGen from `project.yml`) |
| `FlightCompensation/Services/EU261Rules.swift` | All compensation rules (scope, distance bands, delays, cancellations, reductions) |
| `FlightCompensation/Resources/airports.json` | 9,000+ IATA airports with country and coordinates (OurAirports, public domain) |
| `FlightCompensation/firestore.rules`, `storage.rules` | Security rules (per-user access, claims create-only) |
| `FlightCompensation/functions/` | Cloud Function `onClaimCreated`: routes and emails each claim |
| `server/` | `payout_server.py` (dLocal payouts), `email_server.py`, `reconciliation_job.py` |
| `Tests/EU261Core/` | Swift package that runs the EU261 rules tests on macOS or Linux |
| `Config/` | Build-time configuration (`App.xcconfig`, git-ignored `Secrets.xcconfig`) |
| `docs/` | Production checklist and older integration notes |

## Run the app

1. `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig` and fill it in (all keys are optional for local runs).
2. Open `FlightCompensation.xcodeproj` in Xcode 15+ and run the `FlightCompensation` scheme.

Without a FlightRadar24 key the app uses mock flight data. In Debug builds the flight codes
`DELAY001`, `DELAY002` and `CANCEL001` return canned disruptions, and submitted claims are marked
`isTest`, so the backend sends airline emails to the ops inbox instead of the airline.

## Claim flow

1. Passenger details and booking reference (or a parent/guardian claiming for a child)
2. What happened: arrival delay, or cancellation notice and re-routing; eligibility and net payout update live
3. Airline first, or escalation to AESA
4. Proof of travel (boarding pass or booking confirmation); ID optional, required for AESA
5. Agreement: service & fee terms, assignment of claim, power of attorney, privacy notice; each accepted explicitly
6. Signature drawn on screen, confirmed with Face ID; the signed PDF carries an audit trail (time, device, SHA-256)
7. Review and submit: files go to Storage, the claim to Firestore, and `onClaimCreated` emails the airline,
   the passenger and ops (or routes the claim to ops when the airline needs its web form)

Competitor research behind this flow: [docs/research/competitor-claim-flows.md](docs/research/competitor-claim-flows.md).

## Tests

```bash
cd Tests/EU261Core && swift test                      # EU261/UK261 rules
cd FlightCompensation/functions && npm ci && npm test  # claim email routing
npm run test:rules                                     # Firestore/Storage rules (needs Java for the emulator)
python3 -m unittest discover -s server/tests           # payout webhook signature and API token
```

CI runs all of them on every pull request (`.github/workflows/ci.yml`).

## Deploy

See [docs/PRODUCTION_CHECKLIST.md](docs/PRODUCTION_CHECKLIST.md) for every key and setting needed before launch.

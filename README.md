# EZ Committee - Digital Committee Management System

Flutter + Firebase MVP for ROSCA-style rotating savings groups ("committees").

## Implemented Features

- Phone number OTP login (Firebase Authentication)
- Post-OTP password setup (hashed locally before storage)
- Verification workflow
  - CNIC front/back upload
  - live selfie capture
  - terms acceptance
  - manual admin review: pending / approved / rejected
- Committee lifecycle
  - create committee with contribution amount, frequency, total intervals, member limit
  - join committee via invite code
  - gathering -> active -> completed state flow
  - payout order timeline
- Group dashboard
  - progress bar
  - member table with payment status + trust score
  - pay-now path when user has pending/rejected interval payment
- Payment tracking and verification
  - external payment instructions (Easypaisa, JazzCash, bank)
  - transaction ID submission
  - owner approve/reject flow
  - rejected payments become payable again
- Trust scoring
  - on-time / late payment rates
  - trust score percentage
  - at-risk tagging after repeated misses
- Missed-payment handling
  - overdue scan helper
  - reminder and owner-alert notification documents
- Group messaging (real-time Firestore stream)
- Payout flow
  - owner confirms payout with transaction ID
  - recipient confirms payout received
  - full payout timeline visible to members
- Dispute handling
  - users can raise disputes
  - status tracking + admin resolution fields
- Admin panel for manual identity verification

## Tech Stack

- Flutter (Android target in this repo)
- Firebase Auth (phone OTP)
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging token capture

## Project Structure

- `lib/controllers/` app-level state orchestration
- `lib/services/` Firebase data services and business logic
- `lib/models/` domain models
- `lib/screens/` all required user/admin flows
- `firebase/` Firestore and Storage security rules

## Security Notes (MVP)

- Sensitive strings (CNIC/selfie URLs and payment transaction IDs) are encrypted before Firestore storage by `CryptoService`.
- Password is hashed before being persisted to user profile metadata.
- Firestore/Storage rules are provided in:
  - `firebase/firestore.rules`
  - `firebase/storage.rules`

For production hardening, move encryption keys and password policy enforcement to trusted server-side functions.

## Setup

1. Install Flutter SDK.
2. Configure Firebase project and add app config (e.g., `google-services.json` for Android).
3. Enable Firebase services:
   - Authentication -> Phone provider
   - Firestore
   - Storage
   - Cloud Messaging
4. Deploy rules:
   - `firebase deploy --only firestore:rules`
   - `firebase deploy --only storage`
5. Run:
   - `flutter pub get`
   - `flutter run`

## Validation

- Static analysis: `flutter analyze`
- Widget tests: `flutter test`

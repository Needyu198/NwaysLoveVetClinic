# Firebase Cloud Messaging (push notifications)

Push notifications are fully wired in code. Devices register their FCM token
with the backend after login; the backend can push to an account's devices via
the Firebase Admin SDK. Two configuration steps (which require your Firebase /
Apple accounts) are needed for **delivery to real devices**.

## What is already implemented

Flutter:
- `firebase_messaging` added to `pubspec.yaml`.
- `lib/data/messaging_service.dart` — requests permission, gets the FCM token,
  registers it with the backend, listens for token refresh and foreground
  messages, and unregisters on logout. Degrades gracefully if unavailable.
- `lib/main.dart` — registers a top-level background message handler.
- Registration is triggered on session start and cleared on sign-out
  (`lib/data/database_sync.dart`).

Backend:
- `POST /devices/register` and `POST /devices/unregister` (auth-gated) store
  tokens in the `device_tokens` table (`backend/src/schema.js`).
- `backend/src/messaging.js` — `sendToAccount(pool, accountId, {title, body, data})`
  sends via `firebase-admin` and prunes invalid tokens. No-op until credentials
  are configured.

Verified locally: register/unregister endpoints work and persist tokens; the
send path loads and is a safe no-op without credentials.

## Step 1 — Backend service-account credentials (required to send)

1. Firebase Console → project **nwayslovevetclinic** → Project settings →
   Service accounts → **Generate new private key**. This downloads a JSON file.
2. Provide it to the backend using either:
   - `GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/serviceAccount.json`, or
   - `FIREBASE_SERVICE_ACCOUNT='<the JSON contents>'`
   (add to `backend/.env` or the process environment). Keep this file secret;
   do not commit it.
3. Restart the backend. On startup, if credentials are present, FCM is enabled.

## Step 2 — iOS APNs key (required for iOS delivery)

iOS push requires an Apple Push Notification service key uploaded to Firebase.
This needs a **paid Apple Developer account**.

1. Apple Developer → Certificates, Identifiers & Profiles → Keys → create a key
   with **Apple Push Notifications service (APNs)** enabled. Download the `.p8`.
2. Firebase Console → Project settings → Cloud Messaging → **Apple app
   configuration** → upload the APNs key (with Key ID and Team ID).
3. Ensure the Firebase iOS app is registered under the app's real bundle id
   `com.htinaunglynn.seniorProject` (see `docs/FIREBASE_AUTH_SETUP.md`), and that
   Push Notifications + Background Modes (Remote notifications) capabilities are
   enabled in Xcode for the Runner target.

Android needs no extra key (FCM works with `google-services.json`), but confirm
the Android package matches the Firebase Console registration.

## Sending a notification from your code

Call `sendToAccount` where a user should be notified, for example when staff
assign a home-visit doctor or a queue position changes:

```js
const { sendToAccount } = require('./messaging');
await sendToAccount(pool, ownerAccountId, {
  title: 'Queue update',
  body: 'You are next in line.',
  data: { type: 'queue' },
});
```

Until Steps 1–2 are done, calls are safe no-ops and the app continues using the
existing in-app notifications.

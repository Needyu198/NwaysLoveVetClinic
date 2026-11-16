# senior_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# NwayLoveVetClinic

The Flutter app stores operational data in PostgreSQL through the Express API
in `backend/`. For local development, Docker Compose starts PostgreSQL and the
API on the same machine; the database files persist in the `pgdata` volume.

```sh
cp .env.docker.example .env
# Change DB_PASSWORD in .env before starting the database.
docker compose up -d --build db backend
```

Confirm the local API and database are ready:

```sh
curl http://127.0.0.1:5050/health
```

Debug builds now use the local API automatically: Android Studio Emulator uses
`http://10.0.2.2:5050`, while iOS Simulator and desktop use
`http://127.0.0.1:5050`. Remove the old Render
`--dart-define=API_BASE_URL=...` override from the run command so it does not
replace this local default. For a physical phone, use the computer's reachable
LAN address instead, for example:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_LAN_IP:5050
```

The local `pgdata` volume is a separate database from Render. Existing hosted
records are not copied automatically.

For a public deployment that works from any internet connection:

```sh
flutter run --dart-define=API_BASE_URL=https://api.your-domain.example
```

Appointment reminders are sent to the pet owner's registered phone 30 minutes
before the booking. Set `CLINIC_TIME_ZONE` (for example `Asia/Bangkok`) and
`FIREBASE_SERVICE_ACCOUNT` on the deployed backend. The latter must contain the
Firebase service-account JSON. The owner must sign in once on the phone and
allow notifications so its device token is registered. The backend must remain
running for the reminder scheduler to check upcoming appointments.

Android supports these remote reminders with the included Firebase setup. iOS
remote push notifications require a paid Apple Developer team with the Push
Notifications capability and an APNs key connected in Firebase; a free Apple
Personal Team cannot sign an app containing the `aps-environment` entitlement.

Binding to `0.0.0.0` makes the API reachable through the Mac's LAN address, but
it does not publish the Mac to the internet. To use the app from any network,
deploy the backend and PostgreSQL using `deploy/README.md`, expose only the API
through HTTPS, and build the app with that public URL. Never expose PostgreSQL
port 5432 to the internet.

Create another PostgreSQL-backed account with:

```sh
ACCOUNT_PASSWORD='choose-a-password' npm run account:create -- username doctor "Doctor Name"
```

Valid roles are `petOwner`, `doctor`, `staff`, and `systemAdmin`.


## KBZPay invoice QR

Checkout defaults to the supplied personal KBZPay receive QR for Sitt Yan Htun (account ending 2067). The QR identifies the same recipient for every order. Customers scan, enter the invoice amount shown on screen and keep the transaction receipt. Staff match the recipient, amount and transaction ID against the received transfer before reconciling the invoice. The checkout display timer does not expire the personal account QR at KBZPay.

Set `KBZPAY_QR_MODE=merchant` on the backend to use the existing amount-filled merchant integration for newly generated payment attempts.

The backend can generate a MyanmarPay merchant-presented QR from the clinic’s reusable MMQR merchant sticker. Use this mode for a merchant whose acquiring bank supports merchant-generated invoice QRs. Copy the **decoded QR text** from the clinic’s public sticker into `MMQR_MERCHANT_QR` in `backend/.env`, the root `.env` for Docker Compose, or the backend’s environment settings on Render. Restart the backend after setting it. A personal transfer link or a screenshot filename cannot be used as the setting.

At checkout the server preserves the merchant routing, inserts the invoice total in MMK and a unique bill number, and recalculates the checksum. In **Staff → Payments**, open a pending invoice’s payment QR. In KBZPay, choose **Scan**, then check the displayed clinic name and total. This preview can be tested without authorizing a transfer.

The existing acquiring adapter takes precedence when `MMQR_PROVIDER_QR_ENDPOINT` is configured. Use it for a merchant whose bank requires bank-issued dynamic QRs or bank-enforced expiry. The app’s 15-minute display window does not invalidate a saved sticker-based QR at the bank. Payment confirmation continues through the existing verified settlement or staff reconciliation workflow.

[MyanmarPay merchant-presented QR specification](https://myanmarpay.gov.mm/frontend/assets/files/MyanmarQRSpecification.pdf)

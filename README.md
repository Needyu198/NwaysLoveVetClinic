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
in `backend/`.

```sh
cd backend
npm install
npm run migrate
npm start
```

The backend listens on all network interfaces (`0.0.0.0`) by default. The app
uses `http://127.0.0.1:5050` on desktop and web and `http://10.0.2.2:5050` on
the Android emulator. For a physical device on the local network, or for an
internet-accessible HTTPS deployment, pass the reachable API address when
starting Flutter. For a phone on the same local network:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_LAN_IP:5050
```

For a public deployment that works from any internet connection:

```sh
flutter run --dart-define=API_BASE_URL=https://api.your-domain.example
```

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

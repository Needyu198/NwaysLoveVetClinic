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

The default API address is `http://127.0.0.1:5050` on desktop and web, and
`http://10.0.2.2:5050` on the Android emulator. For a physical device or a
deployed API, pass the reachable address when starting Flutter:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_SERVER:5050
```

Create another PostgreSQL-backed account with:

```sh
ACCOUNT_PASSWORD='choose-a-password' npm run account:create -- username doctor "Doctor Name"
```

Valid roles are `petOwner`, `doctor`, `staff`, and `systemAdmin`.

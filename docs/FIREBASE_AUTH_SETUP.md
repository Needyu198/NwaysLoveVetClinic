# Firebase Auth integration

Firebase Auth is now initialized at app startup and mirrors every successful
backend login into the clinic's Firebase project. The backend session remains
the source of truth for API authorization; Firebase Auth is an additional
identity layer (also needed for Cloud Messaging token association).

## What was wired

- `lib/data/firebase_service.dart` — initializes Firebase (`FirebaseService.ensureInitialized`)
  and provides best-effort `signInOrRegister` / `signOut`. All methods degrade
  gracefully: if Firebase is unavailable, the backend login still works.
- `lib/main.dart` — calls `FirebaseService.instance.ensureInitialized()` before
  `runApp`.
- `lib/data/clinic_api.dart` — after a successful backend login it also signs the
  user into Firebase (username mapped to a synthetic email via
  `FirebaseService.emailForIdentifier`), and signs out of Firebase on logout.

## Enable Email/Password sign-in (one-time, Firebase Console)

1. Open the Firebase Console → project **nwayslovevetclinic**.
2. Authentication → Sign-in method → enable **Email/Password**.

## Bundle ID reconciliation (required for iOS correctness + FCM)

There is a mismatch you must fix in the Firebase Console:

- App's real iOS bundle id: `com.htinaunglynn.seniorProject`
  (from `ios/Runner.xcodeproj/project.pbxproj`).
- `ios/Runner/GoogleService-Info.plist` `BUNDLE_ID`: `com.example.seniorProject`.
- Android package (`android/app/google-services.json`): `com.example.senior_project`.

Basic Firebase Auth still initializes despite this (it keys off `GOOGLE_APP_ID`),
but for a clean setup and for Cloud Messaging you should register the app under
the correct bundle id:

1. Firebase Console → Project settings → Your apps.
2. Add / edit the iOS app so its bundle id is `com.htinaunglynn.seniorProject`.
3. Download the regenerated `GoogleService-Info.plist` and replace
   `ios/Runner/GoogleService-Info.plist`.
4. Re-run `flutterfire configure` (or manually update
   `lib/firebase_options.dart` `iosBundleId`).

Do the equivalent for Android if you change its package name.

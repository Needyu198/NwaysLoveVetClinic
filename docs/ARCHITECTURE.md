# Nway's Love Vet Clinic — System Architecture

This document describes the system **as it is actually implemented** in this
repository, and maps it against the original Senior Project Proposal so the
differences are explicit.

Last verified: September 2026.

---

## 1. High-level overview

Nway's Love Vet Clinic is a role-based veterinary clinic management system with
four user roles:

- **Pet Owner** — book appointments, join the queue, request home visits and
  emergencies, view medical history, receive in-app notifications, shop pet
  products.
- **Doctor (Veterinarian)** — manage appointments, medical records, health
  posts, and the live patient queue.
- **Clinic Staff** — walk-in appointments, payments/billing, inventory,
  operational reports, and queue management.
- **System Admin** — user directory, doctor verifications, audit logs.

The system is a **Flutter client** talking to a **Node.js + Express** REST API
backed by **PostgreSQL**.

```
+-------------------+        HTTPS/HTTP (REST + WebSocket)        +------------------------+
|  Flutter client   |  <---------------------------------------> |  Node.js + Express API |
|  (iOS / Android / |     Bearer token in Authorization header   |  (Express 5)           |
|   Web / Desktop)  |                                            +-----------+------------+
+-------------------+                                                        |
     roles: petOwner, doctor, staff, systemAdmin                            | pg (Pool)
                                                                            v
                                                                +------------------------+
                                                                |   PostgreSQL database   |
                                                                |  (NwayLoveVetClinicSever)|
                                                                +------------------------+
```

---

## 2. Technology stack (as built)

| Layer | Technology | Where |
|-------|-----------|-------|
| Client (all roles) | **Flutter** (Dart) | `lib/` |
| Backend API | **Node.js + Express 5** | `backend/src/server.js`, `backend/src/api.js` |
| Database | **PostgreSQL** (`pg` pool) | `backend/src/db.js` |
| Authentication | **Custom** — bcrypt password hashing + opaque DB session tokens | `backend/src/api.js` |
| Real-time | **Socket.io** for live queue updates | `backend/src/realtime.js`, `lib/data/realtime_client.dart` |
| Push notifications | **Firebase Cloud Messaging (FCM)** + in-app DB notifications | see `docs/FCM_SETUP.md` |
| Reporting | **In-app Dart** + optional **Python/Pandas** service | `lib/staff/staff_reports_page.dart`, `reporting/` |
| Staff web app | **React.js** (optional web surface) | `web-staff/` |
| Hosting | Local dev; **Docker + AWS** config provided | `docker-compose.yml`, `deploy/` |

> Note: `jsonwebtoken` is present in `backend/package.json` but the session
> scheme uses random opaque tokens stored (hashed) in the `app_sessions` table,
> not signed JWTs.

---

## 3. Authentication

- `POST /auth/login` (alias `/auth/pet-owner/login`): looks up `app_accounts`
  by username, verifies the password with `bcrypt.compare`, then issues a random
  32-byte token whose SHA-256 hash is stored in `app_sessions` with a 12-hour
  expiry. The raw token + account info is returned.
- Every `/data/*` request and `/auth/logout` must present
  `Authorization: Bearer <token>`; middleware validates the session against an
  active account and role.
- `POST /auth/logout` deletes the session row.

Firebase Auth has since been integrated as an additional sign-in option (see
Task B1 / `lib/login/`), but the custom backend session remains the source of
truth for API authorization.

---

## 4. Data model and sync

All feature data is stored as versioned JSON records in per-feature tables,
served through two generic endpoints:

- `GET /data/:table` — returns records the caller is allowed to read.
- `POST /data/:table/sync` — applies a batch of `changes` and `deletions` with
  optimistic concurrency (stale `version` → HTTP 409).

The Flutter `DatabaseSync` engine (`lib/data/database_sync.dart`) hydrates all
bound stores on login and debounces local edits (300 ms) before flushing diffs.

Access rules are declared centrally in `backend/src/resources.js` per table
(`roles`, `scope`, optional `writers`, `appendOnly`).

### Tables / modules

Appointments (`appointments`, `walk_in_appointments`, `doctor_appointment_state`),
Medical records (`medical_records`), Billing (`payments`), Queue
(`queue_entries`), Inventory (`inventory`), plus profiles, notifications,
reminders, home visits, emergencies, pet care bookings, health posts, messages,
support tickets, doctor verifications, audit logs, and the admin user directory.

---

## 5. Proposal vs. implementation (delta)

| Planned in proposal | As originally built | Current state |
|---------------------|---------------------|---------------|
| Frontend: Flutter (owner, vet) | Flutter | Flutter (unchanged, matches) |
| Frontend: React.js (clinic staff) | Flutter staff UI | Flutter staff UI **plus** optional React web app in `web-staff/` |
| Backend: Node.js + Express | Node + Express 5 | Matches |
| Database: PostgreSQL | PostgreSQL | Matches |
| Auth: Firebase Auth | Custom bcrypt + session tokens | Custom auth + Firebase Auth option |
| Real-time: Socket.io (queue) | Polling/optimistic sync | Socket.io live queue added |
| Push: Firebase Cloud Messaging | In-app DB notifications | FCM wired (needs APNs key for iOS delivery) |
| Reporting: Python/Pandas | In-app Dart reporting | Dart reporting + optional Python/Pandas service |
| Hosting: AWS | Local only | Docker + AWS deploy config provided |

---

## 6. Running locally

```bash
# Backend
cd backend
npm install
npm start          # serves on http://127.0.0.1:5050

# Database (macOS Homebrew example)
brew services start postgresql@14

# Flutter client
flutter run        # physical devices use the .local hostname / API_BASE_URL
```

See `README.md` and the per-feature setup docs under `docs/` for details.

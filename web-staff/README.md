# Clinic Staff Web App (React.js)

A React + Vite web frontend for clinic staff, implementing the proposal's
"Clinic Staff (React.js)" surface. It authenticates against the same Node
backend as the Flutter app and updates live over Socket.io.

## Setup

```bash
cd web-staff
npm install
npm run dev        # http://127.0.0.1:5173
```

Set `VITE_API_BASE_URL` to point at the backend if it is not on
`http://127.0.0.1:5050` (e.g. a LAN IP or deployed URL):

```bash
VITE_API_BASE_URL=http://127.0.0.1:5050 npm run dev
```

## What it does

- **Login** — signs in via `POST /auth/login`; only `staff` / `systemAdmin`
  roles are allowed into the portal (others are signed back out).
- **Live dashboard** — tabs for Queue, Appointments, Inventory, and Payments.
  Tables load from `GET /data/:table` and refresh automatically when the backend
  broadcasts a `data:changed` event over Socket.io (the green dot shows the live
  connection).
- Session token is stored in `localStorage` so a page refresh keeps you signed
  in.

## Structure

- `src/api.js` — REST client mirroring the Flutter `ClinicApi`.
- `src/realtime.js` — Socket.io client for live table updates.
- `src/App.jsx` — login + tabbed dashboard.

## Build

```bash
npm run build      # outputs to dist/
npm run preview    # preview the production build
```

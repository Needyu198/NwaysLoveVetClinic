# Administrator and Staff Web App (React.js)

A unified React + Vite management portal for clinic staff and system
administrators. The authenticated account role selects the correct dashboard,
navigation, and permissions. It uses the same Node backend as the Flutter app
and updates live over Socket.io.

## Setup

```bash
cd web-as
npm install
npm run dev        # http://127.0.0.1:5173
```

Set `VITE_API_BASE_URL` to point at the backend if it is not on
`http://127.0.0.1:5050` (e.g. a LAN IP or deployed URL):

```bash
VITE_API_BASE_URL=http://127.0.0.1:5050 npm run dev
```

## What it does

- **One login** — signs in via `POST /auth/login`; staff and system-admin roles
  are routed to their own workspace (other roles are signed back out).
- **Live dashboard** — tabs for Queue, Appointments, Inventory, and Payments.
  Tables load from `GET /data/:table` and refresh automatically when the backend
  broadcasts a `data:changed` event over Socket.io (the green dot shows the live
  connection).
- Session token is stored in `localStorage` so a page refresh keeps you signed
  in.

## Structure

- `src/api.js` — REST client mirroring the Flutter `ClinicApi`.
- `src/realtime.js` — Socket.io client for live table updates.
- `src/App.jsx` — shared login and role-aware portal shell.
- `src/views.jsx` — staff workspace views.
- `src/adminViews.jsx` — system-administrator workspace views.

## Build

```bash
npm run build      # outputs to dist/
npm run preview    # preview the production build
```

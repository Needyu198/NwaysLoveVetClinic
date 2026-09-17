# Manual workflow testing

## Start all applications

Use separate terminals from the project root:

```bash
cd backend
npm start
```

```bash
cd web-staff
VITE_API_BASE_URL=http://127.0.0.1:5050 npm run dev -- --port 5173
```

Run Flutter on a simulator, browser, or physical device. For a physical device,
replace `YOUR_MAC_LAN_IP` with the Mac's LAN address and keep both devices on the
same network:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_LAN_IP:5050
```

Open the management portal at `http://127.0.0.1:5173`. Staff accounts are sent
to clinic operations, while system-administrator accounts are sent to admin
governance features after using the same sign-in form.

## Socket.IO / WebSocket check

With the backend running and the seeded `petowner` account available, run:

```bash
cd backend
npm run test:realtime
```

A successful result ends with `REALTIME OK`. It verifies that an invalid token
is rejected, a valid WebSocket connection succeeds, and a database sync emits a
`data:changed` event. In both web portals, the header should also change from
`Connecting...` to `Live`. Stop the backend to confirm it returns to
`Connecting...`, then restart it and confirm it becomes `Live` again.

## Cross-application workflow checklist

Keep the mobile app and relevant web portal open at the same time. Do not
refresh the browser unless a step specifically says to do so; live updates
should appear automatically.

1. **Admin account creation**
   - Sign in with a system-administrator account and open **Users & Roles**.
   - Create an owner, doctor, or staff account. Confirm it appears as Pending.
   - Confirm the pending account cannot sign in.
   - Activate it, then sign in from the matching mobile or web portal.
   - Suspend it and confirm its next authenticated request/sign-in is rejected.

2. **Owner appointment to staff web**
   - On mobile, book an appointment as a pet owner.
   - Confirm it appears in web staff **Appointments** without refreshing.
   - In web staff, confirm it, assign a doctor, or reschedule it.
   - On mobile, confirm the booking changes and the owner notification appears.
   - Cancel it from web staff and verify the cancellation on mobile.

3. **Queue**
   - Check the owner into the queue using the normal mobile workflow.
   - In web staff **Queue**, use **Call patient**, **Start consultation**, and
     **Complete**.
   - Confirm every status reaches the owner's mobile queue screen and that call
     and consultation notifications are created.

4. **Walk-ins and payments**
   - Register a walk-in in web staff and confirm it appears immediately.
   - Mark an unpaid payment as paid and verify amount, method, and paid time.

5. **Emergency and home visit**
   - Submit each request from the owner mobile app.
   - Advance the emergency in web staff through review, acceptance, and arrival.
   - Assign a home-visit doctor and advance each visit status.
   - Confirm the owner mobile screens update and the home-visit assignment
     notification appears.

6. **Inventory and messages**
   - Stock an item in/out and submit a restock request in web staff.
   - Confirm the quantities, movements, and request remain after browser reload.
   - Send a clinic message from mobile, reply in web staff, and confirm the reply
     appears on mobile. Resolve the conversation and verify the read state.

7. **Admin dashboard and governance**
   - Confirm user totals, today's appointments, queue, emergencies, low stock,
     expired stock, pending users, and doctor verifications match the data.
   - Approve/reject a doctor verification and confirm an audit entry is added.
   - Activate, suspend, and delete a non-admin test user and verify audit entries.

8. **Call the clinic**
   - Test on a physical phone when possible.
   - Open the owner confirmation dialog and tap **Confirm Call**.
   - Confirm the native Phone app opens with the clinic number filled in.
   - An emulator without a dialer may report that calling is unavailable; this
     does not reproduce real-device URL launching.

9. **Pet ages**
   - Create pets with different birth dates.
   - Open **Profile > My Pets** and verify each card calculates its own age rather
     than showing the same fixed age.

## Automated verification

```bash
cd backend && npm test
cd ../web-staff && npm run build
cd ../web-admin && npm run build
cd .. && flutter analyze
flutter test -r compact test/admin_account_creation_test.dart test/clinic_phone_test.dart test/pet_profile_page_test.dart
```

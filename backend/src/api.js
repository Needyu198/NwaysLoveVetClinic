const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const { resources } = require('./resources');
const { broadcastChange } = require('./realtime');
const { sendToAccount } = require('./messaging');
const { resetEmailConfigured, sendPasswordResetEmail } = require('./passwordResetEmail');
const hash = token => crypto.createHash('sha256').update(token).digest('hex');
const fail = (status, message) => Object.assign(new Error(message), { status });
// Booking policy: at most this many active bookings per veterinarian/date/time
// slot, and a pet owner is suspended once their cancellations reach the
// threshold. Both are overridable via environment for different clinics.
const APPOINTMENT_SLOT_CAPACITY = Math.max(1, Number(process.env.APPOINTMENT_SLOT_CAPACITY) || 2);
const APPOINTMENT_CANCELLATION_SUSPEND_THRESHOLD = Math.max(1, Number(process.env.APPOINTMENT_CANCELLATION_SUSPEND_THRESHOLD) || 3);
const normalizedPhone = value => String(value || '').replace(/[^0-9]/g, '');
const PASSWORD_RESET_GENERIC_MESSAGE = 'If an active account matches those details, a verification code has been sent to its registered email.';
const passwordResetIdentifier = value => String(value || '').trim().toLowerCase();
const passwordResetCodeHash = (account, code) => hash(`${account.id}:${code}:${account.password_hash}`);
const secureHashEquals = (left, right) => {
  const a = Buffer.from(String(left || ''), 'hex');
  const b = Buffer.from(String(right || ''), 'hex');
  return a.length === b.length && a.length > 0 && crypto.timingSafeEqual(a, b);
};
const duplicateProtectedBookingTables = new Set(['appointments', 'home_visits', 'pet_care_bookings']);
const normalizedBookingText = value => String(value || '').trim().toLowerCase();
const bookingPetStableId = value => {
  const pet = value?.pet || {};
  return normalizedBookingText(pet.id || pet.petKey);
};
const bookingPetFallback = value => {
  const pet = value?.pet || {};
  return [pet.name, pet.species, pet.breed].map(normalizedBookingText).join('|');
};
const sameBookingPet = (left, right) => {
  const leftId = bookingPetStableId(left);
  const rightId = bookingPetStableId(right);
  return leftId && rightId
    ? leftId === rightId
    : bookingPetFallback(left) === bookingPetFallback(right);
};
const bookingDate = value => String(value?.date || '').slice(0, 10);
const bookingTime = value => String(value?.time || '').trim();
const activeBooking = (table, value) => {
  const status = normalizedBookingText(value?.status);
  if (table === 'appointments') return status !== 'cancelled';
  return status !== 'completed';
};
const clinicDateToday = () => {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: process.env.CLINIC_TIME_ZONE || 'Asia/Bangkok',
    year: 'numeric', month: '2-digit', day: '2-digit',
  }).formatToParts(new Date());
  const value = Object.fromEntries(parts.map(part => [part.type, part.value]));
  return `${value.year}-${value.month}-${value.day}`;
};
const queueServiceGroupForAppointment = appointment => {
  const name = String(appointment?.service?.name || appointment?.service || '').toLowerCase();
  return ['pet care','grooming','bathing','boarding','day care','overnight stay','nail clipping','ear cleaning','anal gland cleaning']
    .some(value => name.includes(value)) ? 'petCareService' : 'medicalService';
};
async function findAccountByIdentifier(database, identifier) {
  const normalized = String(identifier || '').trim().toLowerCase();
  const phoneDigits = /^[+()\d\s.-]+$/.test(normalized)
    ? normalizedPhone(normalized)
    : '';
  const phone = phoneDigits.length >= 6 ? phoneDigits : '';
  const matches = (await database.query(
    `SELECT * FROM app_accounts WHERE active=TRUE AND (
      LOWER(username)=$1 OR LOWER(COALESCE(email,''))=$1 OR
      ($2<>'' AND regexp_replace(COALESCE(phone,''),'[^0-9]','','g')=$2)) LIMIT 2`,
    [normalized, phone],
  )).rows;
  if (matches.length === 1) return matches[0];
  if (matches.length > 1) return null;
  const old = (await database.query(
    'SELECT * FROM pet_owners WHERE LOWER(username) = $1',
    [normalized],
  )).rows[0];
  return old ? { ...old, id: `owner-${old.id}`, role: 'petOwner' } : null;
}
async function syncUserDirectoryAccount(client, value, existing, sessionAccountId) {
  const roles = {owner:'petOwner',doctor:'doctor',staff:'staff',admin:'systemAdmin'};
  if (!roles[value.role] || !['pending','active','suspended'].includes(value.status)) throw fail(400, 'Invalid user role or status.');
  if (value.id === sessionAccountId && (value.status !== 'active' || roles[value.role] !== 'systemAdmin')) throw fail(400, 'You cannot remove your own administrator access.');
  if (existing && value.id !== existing.data.value.id) throw fail(400, 'Account identity cannot change.');
  // A password is only ever sent when the admin first creates the account.
  // Use it for the bcrypt hash, then remove it from directory JSON.
  const newPassword = typeof value.password === 'string' ? value.password : '';
  delete value.password;
  if (typeof value.name !== 'string' || !value.name.trim() || value.name.length > 200) throw fail(400, 'A valid full name is required.');
  if (typeof value.email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.email) || value.email.length > 254) throw fail(400, 'A valid email is required.');
  if (typeof value.phone !== 'string' || value.phone.trim().length < 6 || value.phone.length > 40) throw fail(400, 'A valid phone number is required.');
  const email = value.email.trim().toLowerCase();
  const username = String(value.username || email.split('@')[0]).trim().toLowerCase();
  const phone = value.phone.trim();
  const phoneKey = normalizedPhone(phone);
  if (!/^[a-z0-9._-]{3,64}$/.test(username)) throw fail(400, 'Username must be 3–64 letters, numbers, dots, dashes, or underscores.');
  if (phoneKey.length < 6) throw fail(400, 'A valid phone number is required.');
  value.username = username;
  value.email = email;
  value.phone = phone;
  const clash = (await client.query(
    `SELECT id FROM app_accounts WHERE id<>$1 AND (
      LOWER(username) IN ($2,$3) OR LOWER(COALESCE(email,'')) IN ($2,$3) OR
      regexp_replace(COALESCE(phone,''),'[^0-9]','','g')=$4) LIMIT 1`,
    [value.id, username, email, phoneKey],
  )).rows[0];
  if (clash) throw fail(409, 'An account with this username, email, or phone number already exists.');
  const account = (await client.query('SELECT id FROM app_accounts WHERE id=$1', [value.id])).rows[0];
  if (account) {
    await client.query(
      'UPDATE app_accounts SET username=$2,email=$3,phone=$4,full_name=$5,role=$6,active=$7 WHERE id=$1',
      [value.id,username,email,phone,value.name,roles[value.role],value.status==='active'],
    );
    return;
  }
  if (newPassword.length < 8 || newPassword.length > 1024) throw fail(400, 'A password of at least 8 characters is required for a new account.');
  await client.query(
    'INSERT INTO app_accounts(id,username,email,phone,password_hash,full_name,role,active) VALUES($1,$2,$3,$4,$5,$6,$7,$8)',
    [value.id,username,email,phone,await bcrypt.hash(newPassword, 12),value.name,roles[value.role],value.status==='active'],
  );
}
function installApi(app, pool, options = {}) {
  const deliverPasswordResetEmail = options.sendPasswordResetEmail || sendPasswordResetEmail;
  const passwordResetDeliveryConfigured = options.passwordResetEmailConfigured ??
    (options.sendPasswordResetEmail ? true : resetEmailConfigured());
  const wrap = fn => async (req, res) => {
    try { await fn(req, res); } catch (e) {
      if (!e.status) console.error('Database request failed:', e.code || e.message);
      res.status(e.status || 503).json({ message: e.status ? e.message : 'Database unavailable. Please retry.' });
    }
  };
  app.post(['/auth/login', '/auth/pet-owner/login'], wrap(async (req, res) => {
    const username = String(req.body.username || '').trim().toLowerCase();
    const password = String(req.body.password || '');
    if (!username || !password || username.length > 254 || password.length > 1024) throw fail(400, 'Username and password required.');
    const account = await findAccountByIdentifier(pool, username);
    if (!account || !(await bcrypt.compare(password, account.password_hash))) throw fail(401, 'Invalid username or password.');
    const token = crypto.randomBytes(32).toString('hex');
    await pool.query("INSERT INTO app_sessions(token_hash, account_id, role, expires_at) VALUES($1,$2,$3,NOW() + INTERVAL '12 hours')", [hash(token), account.id, account.role]);
    res.json({ token, account: { id: account.id, username: account.username, email: account.email, phone: account.phone, fullName: account.full_name, role: account.role } });
  }));
  app.post('/auth/forgot-password', wrap(async (req, res) => {
    if (!passwordResetDeliveryConfigured) {
      throw fail(503, 'Password recovery email is not configured. Please contact the clinic.');
    }
    const identifier = passwordResetIdentifier(req.body.identifier);
    if (!identifier || identifier.length > 254) throw fail(400, 'Enter your registered email, username, or phone number.');
    const identifierHash = hash(identifier);
    const ipHash = hash(String(req.ip || req.socket?.remoteAddress || 'unknown'));
    const client = await pool.connect();
    let account;
    let code;
    try {
      await client.query('BEGIN');
      await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`password-reset:${identifierHash}`]);
      const limits = (await client.query(
        `SELECT
          COUNT(*) FILTER (WHERE identifier_hash=$1)::int AS identifier_count,
          COUNT(*) FILTER (WHERE ip_hash=$2)::int AS ip_count
         FROM password_reset_audit
         WHERE event='request' AND created_at>NOW()-INTERVAL '15 minutes'`,
        [identifierHash, ipHash],
      )).rows[0];
      if (limits.identifier_count >= 3 || limits.ip_count >= 10) {
        await client.query('COMMIT');
        return res.json({ message: PASSWORD_RESET_GENERIC_MESSAGE });
      }
      account = await findAccountByIdentifier(client, identifier);
      await client.query(
        `INSERT INTO password_reset_audit(event,identifier_hash,account_id,ip_hash)
         VALUES('request',$1,$2,$3)`,
        [identifierHash, account?.id || null, ipHash],
      );
      if (account?.email) {
        code = crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
        await client.query(
          `INSERT INTO password_reset_codes(account_id,code_hash,expires_at,attempts,consumed_at,requested_at)
           VALUES($1,$2,NOW()+INTERVAL '10 minutes',0,NULL,NOW())
           ON CONFLICT(account_id) DO UPDATE SET
             code_hash=EXCLUDED.code_hash,expires_at=EXCLUDED.expires_at,
             attempts=0,consumed_at=NULL,requested_at=NOW()`,
          [account.id, passwordResetCodeHash(account, code)],
        );
      }
      await client.query("DELETE FROM password_reset_codes WHERE expires_at<NOW()-INTERVAL '1 day'");
      await client.query("DELETE FROM password_reset_audit WHERE created_at<NOW()-INTERVAL '90 days'");
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    if (account?.email && code) {
      Promise.resolve().then(() => deliverPasswordResetEmail({
        to: account.email,
        name: account.full_name,
        code,
      })).catch(async error => {
        console.error('Password reset email failed:', error.message);
        try {
          await pool.query(
            `INSERT INTO password_reset_audit(event,identifier_hash,account_id,ip_hash)
             VALUES('delivery_failed',$1,$2,$3)`,
            [identifierHash, account.id, ipHash],
          );
        } catch (_) { /* audit failure must not expose account existence */ }
      });
    }
    res.json({ message: PASSWORD_RESET_GENERIC_MESSAGE });
  }));
  app.post('/auth/reset-password', wrap(async (req, res) => {
    const identifier = passwordResetIdentifier(req.body.identifier);
    const code = String(req.body.code || '').trim();
    const newPassword = String(req.body.newPassword || '');
    if (!identifier || identifier.length > 254) throw fail(400, 'Enter your registered account identifier.');
    if (!/^\d{6}$/.test(code)) throw fail(400, 'Enter the six-digit verification code.');
    if (newPassword.length < 8 || newPassword.length > 1024) throw fail(400, 'New password must be at least 8 characters.');
    const identifierHash = hash(identifier);
    const ipHash = hash(String(req.ip || req.socket?.remoteAddress || 'unknown'));
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const account = await findAccountByIdentifier(client, identifier);
      if (!account) {
        await client.query(
          `INSERT INTO password_reset_audit(event,identifier_hash,account_id,ip_hash)
           VALUES('verification_failed',$1,NULL,$2)`,
          [identifierHash, ipHash],
        );
        await client.query('COMMIT');
        throw fail(400, 'Invalid or expired verification code.');
      }
      const reset = (await client.query(
        'SELECT * FROM password_reset_codes WHERE account_id=$1 FOR UPDATE',
        [account.id],
      )).rows[0];
      const valid = reset && !reset.consumed_at && reset.attempts < 5 &&
        new Date(reset.expires_at).getTime() > Date.now() &&
        secureHashEquals(reset.code_hash, passwordResetCodeHash(account, code));
      if (!valid) {
        if (reset && !reset.consumed_at) {
          await client.query(
            'UPDATE password_reset_codes SET attempts=attempts+1 WHERE account_id=$1',
            [account.id],
          );
        }
        await client.query(
          `INSERT INTO password_reset_audit(event,identifier_hash,account_id,ip_hash)
           VALUES('verification_failed',$1,$2,$3)`,
          [identifierHash, account.id, ipHash],
        );
        await client.query('COMMIT');
        throw fail(400, 'Invalid or expired verification code.');
      }
      const newHash = await bcrypt.hash(newPassword, 12);
      await client.query('UPDATE app_accounts SET password_hash=$2 WHERE id=$1', [account.id, newHash]);
      await client.query('UPDATE password_reset_codes SET consumed_at=NOW() WHERE account_id=$1', [account.id]);
      await client.query('DELETE FROM app_sessions WHERE account_id=$1', [account.id]);
      await client.query(
        `INSERT INTO password_reset_audit(event,identifier_hash,account_id,ip_hash)
         VALUES('completed',$1,$2,$3)`,
        [identifierHash, account.id, ipHash],
      );
      await client.query('COMMIT');
      res.json({ ok: true });
    } catch (error) {
      try { await client.query('ROLLBACK'); } catch (_) { /* transaction may already be committed */ }
      throw error;
    } finally {
      client.release();
    }
  }));
  app.use(['/data', '/reports', '/queue', '/auth/logout', '/auth/change-password', '/devices'], async (req, res, next) => {
    try {
      const token = (req.headers.authorization || '').replace(/^Bearer /, '');
      const session = (await pool.query('SELECT s.* FROM app_sessions s JOIN app_accounts a ON a.id=s.account_id AND a.active AND a.role=s.role WHERE s.token_hash=$1 AND s.expires_at>NOW()', [hash(token)])).rows[0];
      if (!session) return res.status(401).json({ message: 'Please sign in again.' });
      req.session = session;
      next();
    } catch (_) { res.status(503).json({ message: 'Database unavailable.' }); }
  });
  app.post('/auth/logout', wrap(async (req, res) => {
    await pool.query('DELETE FROM app_sessions WHERE token_hash=$1', [req.session.token_hash]);
    res.json({ ok: true });
  }));
  // Change the signed-in account's password. Verifies the current password,
  // then updates the bcrypt hash and revokes every OTHER session so stale
  // logins can't linger (the current device keeps its session).
  app.post('/auth/change-password', wrap(async (req, res) => {
    const currentPassword = String(req.body.currentPassword || '');
    const newPassword = String(req.body.newPassword || '');
    if (!currentPassword || !newPassword) throw fail(400, 'Current and new passwords are required.');
    if (newPassword.length < 8 || newPassword.length > 1024) throw fail(400, 'New password must be at least 8 characters.');
    const account = (await pool.query('SELECT id, password_hash FROM app_accounts WHERE id=$1 AND active=TRUE', [req.session.account_id])).rows[0];
    if (!account) throw fail(404, 'Account not found.');
    if (!(await bcrypt.compare(currentPassword, account.password_hash))) throw fail(401, 'Current password is incorrect.');
    const newHash = await bcrypt.hash(newPassword, 12);
    await pool.query('UPDATE app_accounts SET password_hash=$2 WHERE id=$1', [account.id, newHash]);
    // Keep this device signed in; drop all other sessions for the account.
    await pool.query('DELETE FROM app_sessions WHERE account_id=$1 AND token_hash<>$2', [account.id, req.session.token_hash]);
    res.json({ ok: true });
  }));
  // Register (or refresh) this device's FCM token for the signed-in account.
  app.post('/devices/register', wrap(async (req, res) => {
    const token = String(req.body.token || '').trim();
    const platform = String(req.body.platform || 'unknown').slice(0, 32);
    if (!token || token.length > 4096) throw fail(400, 'A device token is required.');
    await pool.query(
      `INSERT INTO device_tokens(token, account_id, platform) VALUES($1,$2,$3)
       ON CONFLICT (token) DO UPDATE SET account_id=EXCLUDED.account_id, platform=EXCLUDED.platform, updated_at=NOW()`,
      [token, req.session.account_id, platform],
    );
    res.json({ ok: true });
  }));
  // Remove this device's token (e.g. on logout / permission revoked).
  app.post('/devices/unregister', wrap(async (req, res) => {
    const token = String(req.body.token || '').trim();
    if (token) await pool.query('DELETE FROM device_tokens WHERE token=$1 AND account_id=$2', [token, req.session.account_id]);
    res.json({ ok: true });
  }));

  const requireClinic = req => {
    if (!['staff', 'doctor', 'systemAdmin'].includes(req.session.role)) {
      throw fail(403, 'Clinic access required.');
    }
  };
  const terminalQueueStatuses = new Set(['completed', 'missed', 'cancelled']);
  const queueTransitions = {
    waiting: new Set(['called', 'missed', 'cancelled']),
    called: new Set(['arrived', 'missed', 'cancelled']),
    arrived: new Set(['inConsultation', 'missed', 'cancelled']),
    inConsultation: new Set(['completed']),
  };
  const appointmentStatusForQueue = {
    waiting: 'Checked In',
    called: 'Called',
    arrived: 'Arrived',
    inConsultation: 'In Consultation',
    completed: 'Completed',
    missed: 'Missed',
    cancelled: 'Cancelled',
  };
  const saveOwnerNotification = async (client, ownerId, title, message) => {
    const id = `queue-notification:${crypto.randomUUID()}`;
    const value = {
      id,
      title,
      message,
      createdAt: new Date().toISOString(),
      read: false,
    };
    await client.query(
      `INSERT INTO owner_notifications(id,owner_id,data) VALUES($1,$2,$3)`,
      [id, ownerId, { key: `${ownerId}:${id}`, value }],
    );
    return { title, message };
  };

  // Return an owner's active tickets with position and wait derived from the
  // complete clinic queue. Position/ETA are deliberately not owner-writable.
  app.get('/queue/my', wrap(async (req, res) => {
    if (req.session.role !== 'petOwner') throw fail(403, 'Pet owner access required.');
    const today = clinicDateToday();
    const rows = (await pool.query(`SELECT id,owner_id,data,version FROM queue_entries
      WHERE (data->'value'->>'status') NOT IN ('completed','missed','cancelled')
        AND data->'value'->>'clinicDate'=$1
      ORDER BY COALESCE(data->'value'->>'serviceGroup','medicalService'),
        CASE data->'value'->>'priority' WHEN 'urgent' THEN 0 ELSE 1 END,
        (data->'value'->>'sequence')::int, created_at`, [today])).rows;
    let activeAhead = 0;
    let currentGroup = null;
    const records = [];
    for (const row of rows) {
      const serviceGroup = row.data.value.serviceGroup ||
        queueServiceGroupForAppointment(row.data.value.appointment);
      if (serviceGroup !== currentGroup) {
        currentGroup = serviceGroup;
        activeAhead = 0;
      }
      const status = row.data.value.status;
      const waiting = status === 'waiting';
      if (row.owner_id === req.session.account_id) {
        records.push({
          ...row,
          data: {
            ...row.data,
            value: {
              ...row.data.value,
              serviceGroup,
              position: waiting ? activeAhead + 1 : 0,
              petsAhead: waiting ? activeAhead : 0,
              estimatedWaitMinutes: waiting ? activeAhead * 10 : 0,
            },
          },
        });
      }
      if (waiting) activeAhead += 1;
    }
    res.json({ records, refreshedAt: new Date().toISOString() });
  }));

  // Allocate the day's queue number under a row lock. Opening an owner screen
  // can never create a ticket; check-in is a clinic-only operation.
  app.post('/queue/check-in', wrap(async (req, res) => {
    requireClinic(req);
    const appointmentId = String(req.body.appointmentId || '');
    const requestedPriority = String(req.body.priority || 'normal');
    if (!appointmentId || appointmentId.length > 250) throw fail(400, 'A valid appointment is required.');
    if (!['normal', 'urgent'].includes(requestedPriority)) throw fail(400, 'Invalid queue priority.');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const appointmentRows = (await client.query(
        `SELECT * FROM appointments WHERE data->'value'->>'id'=$1 FOR UPDATE`,
        [appointmentId],
      )).rows;
      if (appointmentRows.length !== 1) throw fail(appointmentRows.length ? 409 : 404, 'Appointment not found or is not unique.');
      const appointmentRow = appointmentRows[0];
      const appointment = appointmentRow.data.value;
      if (appointment.service?.homeVisit) throw fail(400, 'Home visits do not use the clinic queue.');
      if (!['Pending', 'Confirmed', 'Checked In'].includes(appointment.status)) {
        throw fail(409, `This appointment cannot be checked in from ${appointment.status}.`);
      }
      const existing = (await client.query(
        `SELECT id,owner_id,data,version FROM queue_entries
         WHERE owner_id=$1 AND (data->'value'->>'appointmentId'=$2 OR data->'value'->'appointment'->>'id'=$2)
           AND data->'value'->>'clinicDate'=$3
         ORDER BY created_at DESC LIMIT 1 FOR UPDATE`,
        [appointmentRow.owner_id, appointmentId, clinicDateToday()],
      )).rows[0];
      if (existing && !terminalQueueStatuses.has(existing.data.value.status)) {
        await client.query('COMMIT');
        return res.json({ record: existing, created: false });
      }
      const clinicDate = String(appointment.date || '').slice(0, 10) || new Date().toISOString().slice(0, 10);
      if (clinicDate !== clinicDateToday()) throw fail(409, "Only today's appointments can join the live queue.");
      const serviceGroup = queueServiceGroupForAppointment(appointment);
      const counter = (await client.query(
        `INSERT INTO queue_daily_counters(clinic_date,last_number) VALUES($1,1)
         ON CONFLICT(clinic_date) DO UPDATE SET last_number=queue_daily_counters.last_number+1
         RETURNING last_number`,
        [clinicDate],
      )).rows[0].last_number;
      const queueNumber = `Q${String(counter).padStart(3, '0')}`;
      const now = new Date().toISOString();
      const petName = String(appointment.pet?.name || 'pet');
      const petId = String(appointment.pet?.id || `${appointmentRow.owner_id}:${petName.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`);
      const value = {
        appointmentId,
        ownerId: appointmentRow.owner_id,
        petId,
        appointment,
        clinicDate,
        sequence: counter,
        queueNumber,
        serviceGroup,
        priority: requestedPriority,
        status: 'waiting',
        checkedInAt: now,
        calledAt: null,
        arrivedAt: null,
        consultationStartedAt: null,
        completedAt: null,
        assignedDoctor: appointment.veterinarian || '',
        room: '',
        delayReason: '',
        medicalRecordId: null,
        ownerAcknowledgedAt: null,
        version: 1,
      };
      const id = `queue:${clinicDate}:${String(counter).padStart(6, '0')}`;
      const key = `${appointmentRow.owner_id}:${appointmentId}`;
      const record = (await client.query(
        `INSERT INTO queue_entries(id,owner_id,data) VALUES($1,$2,$3)
         RETURNING id,owner_id,data,version`,
        [id, appointmentRow.owner_id, { key, value }],
      )).rows[0];
      const appointmentData = structuredClone(appointmentRow.data);
      appointmentData.value.status = 'Checked In';
      await client.query('UPDATE appointments SET data=$2,version=version+1,updated_at=NOW() WHERE id=$1', [appointmentRow.id, appointmentData]);
      const notification = await saveOwnerNotification(
        client,
        appointmentRow.owner_id,
        'Queue check-in',
        `${petName} is checked in as ${queueNumber}.`,
      );
      await client.query('COMMIT');
      broadcastChange('appointments', { ownerId: appointmentRow.owner_id });
      broadcastChange('queue_entries', { ownerId: appointmentRow.owner_id });
      broadcastChange('owner_notifications', { ownerId: appointmentRow.owner_id });
      await sendToAccount(pool, appointmentRow.owner_id, {
        title: notification.title,
        body: notification.message,
        data: { type: 'queue', appointmentId },
      });
      res.status(201).json({ record, created: true });
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally { client.release(); }
  }));

  app.post('/queue/:appointmentId/transition', wrap(async (req, res) => {
    requireClinic(req);
    const appointmentId = String(req.params.appointmentId || '');
    const nextStatus = String(req.body.status || '');
    const expectedVersion = Number(req.body.version);
    if (!Number.isInteger(expectedVersion) || expectedVersion < 1) throw fail(400, 'A queue version is required.');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const ticketRows = (await client.query(
        `SELECT * FROM queue_entries
         WHERE (data->'value'->>'appointmentId'=$1 OR data->'value'->'appointment'->>'id'=$1)
           AND data->'value'->>'clinicDate'=$2
         ORDER BY created_at DESC FOR UPDATE`,
        [appointmentId, clinicDateToday()],
      )).rows;
      if (ticketRows.length !== 1) throw fail(ticketRows.length ? 409 : 404, 'Queue ticket not found or is not unique.');
      const ticket = ticketRows[0];
      if (ticket.version !== expectedVersion) throw fail(409, 'This queue ticket changed. Refresh before trying again.');
      const value = structuredClone(ticket.data.value);
      const current = value.status === 'almostTurn' ? 'waiting' : value.status;
      if (nextStatus !== current && !queueTransitions[current]?.has(nextStatus)) {
        throw fail(409, `Queue cannot move from ${current} to ${nextStatus}.`);
      }
      const now = new Date().toISOString();
      value.status = nextStatus;
      value.version = ticket.version + 1;
      if (nextStatus !== current && nextStatus === 'called') value.calledAt = now;
      if (nextStatus !== current && nextStatus === 'arrived') value.arrivedAt = now;
      if (nextStatus !== current && nextStatus === 'inConsultation') value.consultationStartedAt = now;
      if (nextStatus !== current && nextStatus === 'completed') {
        value.completedAt = now;
        value.medicalRecordId = req.body.medicalRecordId || value.medicalRecordId || null;
        if (!value.medicalRecordId) throw fail(400, 'Complete the medical record before completing the queue ticket.');
        const medicalRecord = (await client.query(
          `SELECT 1 FROM medical_records
           WHERE data->'value'->>'id'=$1
             AND data->'value'->>'appointmentId'=$2
             AND data->'value'->>'finalized'='true'
           LIMIT 1`,
          [value.medicalRecordId, appointmentId],
        )).rows[0];
        if (!medicalRecord) throw fail(409, 'The finalized medical record must be saved before completing this queue ticket.');
      }
      if (typeof req.body.room === 'string') value.room = req.body.room.trim().slice(0, 100);
      if (typeof req.body.delayReason === 'string') value.delayReason = req.body.delayReason.trim().slice(0, 500);
      if (typeof req.body.assignedDoctor === 'string') {
        const assignedDoctor = req.body.assignedDoctor.trim().slice(0, 200);
        if (!assignedDoctor) throw fail(400, 'An assigned doctor is required.');
        value.assignedDoctor = assignedDoctor;
      }
      const data = { ...ticket.data, value };
      const saved = (await client.query(
        `UPDATE queue_entries SET data=$2,version=version+1,updated_at=NOW()
         WHERE id=$1 RETURNING id,owner_id,data,version`,
        [ticket.id, data],
      )).rows[0];
      const appointmentRow = (await client.query(
        `SELECT * FROM appointments WHERE owner_id=$1 AND data->'value'->>'id'=$2 FOR UPDATE`,
        [ticket.owner_id, appointmentId],
      )).rows[0];
      if (appointmentRow) {
        const appointmentData = structuredClone(appointmentRow.data);
        appointmentData.value.status = appointmentStatusForQueue[nextStatus];
        if (typeof req.body.assignedDoctor === 'string') {
          appointmentData.value.veterinarian = value.assignedDoctor;
        }
        await client.query('UPDATE appointments SET data=$2,version=version+1,updated_at=NOW() WHERE id=$1', [appointmentRow.id, appointmentData]);
      }
      const petName = String(value.appointment?.pet?.name || 'Your pet');
      let notification = null;
      if (typeof req.body.delayReason === 'string' && value.delayReason) {
        notification = await saveOwnerNotification(
          client,
          ticket.owner_id,
          'Queue delay',
          `${petName}: ${value.delayReason}`,
        );
      } else if (typeof req.body.assignedDoctor === 'string') {
        notification = await saveOwnerNotification(
          client,
          ticket.owner_id,
          'Doctor assigned',
          `${value.assignedDoctor} is now assigned to ${petName}.`,
        );
      } else if (nextStatus !== current) {
        const content = {
          called: ['It is your turn', `${petName}, please proceed to ${value.room || 'the reception desk'}.`],
          arrived: ['Arrival confirmed', `${petName}'s arrival has been recorded.`],
          inConsultation: ['Consultation started', `${petName}'s consultation is now in progress.`],
          completed: ['Visit completed', `${petName}'s visit is complete and the medical record is available.`],
          missed: ['Queue ticket missed', `${petName}'s queue ticket was marked missed.`],
          cancelled: ['Queue ticket cancelled', `${petName}'s queue ticket was cancelled.`],
        }[nextStatus];
        if (content) {
          notification = await saveOwnerNotification(
            client,
            ticket.owner_id,
            content[0],
            content[1],
          );
        }
      }
      await client.query('COMMIT');
      broadcastChange('appointments', { ownerId: ticket.owner_id });
      broadcastChange('queue_entries', { ownerId: ticket.owner_id });
      if (notification) {
        broadcastChange('owner_notifications', { ownerId: ticket.owner_id });
        await sendToAccount(pool, ticket.owner_id, {
          title: notification.title,
          body: notification.message,
          data: { type: 'queue', appointmentId, status: nextStatus },
        });
      }
      res.json({ record: saved });
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally { client.release(); }
  }));

  app.post('/queue/:appointmentId/acknowledge', wrap(async (req, res) => {
    if (req.session.role !== 'petOwner') throw fail(403, 'Pet owner access required.');
    const ticket = (await pool.query(
      `SELECT * FROM queue_entries WHERE owner_id=$1 AND data->'value'->>'appointmentId'=$2
       AND data->'value'->>'clinicDate'=$3
       ORDER BY created_at DESC LIMIT 1`,
      [req.session.account_id, req.params.appointmentId, clinicDateToday()],
    )).rows[0];
    if (!ticket || ticket.data.value.status !== 'called') throw fail(409, 'Only a called queue ticket can be acknowledged.');
    const value = { ...ticket.data.value, ownerAcknowledgedAt: new Date().toISOString(), version: ticket.version + 1 };
    const saved = (await pool.query(
      `UPDATE queue_entries SET data=$2,version=version+1,updated_at=NOW()
       WHERE id=$1 AND version=$3 RETURNING id,owner_id,data,version`,
      [ticket.id, { ...ticket.data, value }, ticket.version],
    )).rows[0];
    if (!saved) throw fail(409, 'This queue ticket changed. Refresh before trying again.');
    broadcastChange('queue_entries', { ownerId: ticket.owner_id });
    res.json({ record: saved });
  }));
  const staffReportNames = new Set(['appointments', 'queue', 'cancellations', 'payments', 'home-visits']);
  app.get('/reports/:name', wrap(async (req, res) => {
    if (!['staff', 'systemAdmin'].includes(req.session.role)) throw fail(403, 'Staff access required.');
    if (!staffReportNames.has(req.params.name)) throw fail(404, 'Unknown report.');
    const baseUrl = (process.env.REPORTING_URL || 'http://127.0.0.1:5060').replace(/\/$/, '');
    let response;
    try {
      response = await fetch(`${baseUrl}/reports/staff/${encodeURIComponent(req.params.name)}`, {
        signal: AbortSignal.timeout(10000),
      });
    } catch (_) {
      throw fail(503, 'The Python/Pandas reporting service is unavailable.');
    }
    let payload;
    try { payload = await response.json(); } catch (_) { throw fail(503, 'The reporting service returned an invalid response.'); }
    if (!response.ok) throw fail(response.status >= 500 ? 503 : response.status, payload.message || 'Report generation failed.');
    res.json(payload);
  }));
  const policy = req => {
    const p = Object.hasOwn(resources, req.params.table) && resources[req.params.table];
    if (!p) throw fail(404, 'Unknown database table.');
    if (!p.roles.includes(req.session.role)) throw fail(403, 'Access denied.');
    return p;
  };
  const ownOnly = (p, session) => p.scope === 'private' || (p.scope === 'owner' && session.role === 'petOwner');
  app.get('/data/:table', wrap(async (req, res) => {
    const p = policy(req);
    if (req.params.table === 'clinic_directory') {
      // Public directory of doctors/staff. Only exposes booking-relevant public
      // fields; private contact and credential data remain in role-owned tables.
      const result = await pool.query(`SELECT a.id, a.id AS owner_id, 1 AS version,
        jsonb_build_object('key',a.id,'value',jsonb_build_object(
          'id',a.id,
          'name',COALESCE(
            NULLIF(dp.data->'value'->>'name',''),
            NULLIF(a.full_name, ''),
            a.username
          ),
          'role',a.role,
          'photoUrl',COALESCE(dp.data->'value'->>'photoUrl',sp.data->'value'->>'photoPath'),
          'specialty',COALESCE(dp.data->'value'->>'specialty',sp.data->'value'->>'shift'),
          'available',CASE WHEN a.role='staff'
            THEN COALESCE(sp.data->'value'->>'onShift' = 'true', TRUE)
            ELSE COALESCE(dp.data->'value'->>'acceptingAppointments' = 'true', TRUE)
          END)) AS data
        FROM app_accounts a
        LEFT JOIN doctor_profiles dp ON dp.owner_id = a.id
        LEFT JOIN staff_profiles sp ON sp.owner_id = a.id
        WHERE a.active AND a.role IN ('doctor','staff') ORDER BY a.full_name,a.id`);
      return res.json({records:result.rows});
    }
    const restricted = ownOnly(p, req.session);
    const rows = await pool.query(`SELECT id, owner_id, data, version FROM ${req.params.table}${restricted ? ' WHERE owner_id=$1' : ''} ORDER BY created_at, id`, restricted ? [req.session.account_id] : []);
    res.json({ records: rows.rows });
  }));
  app.post('/data/:table/sync', wrap(async (req, res) => {
    const p = policy(req);
    if (!(p.writers || p.roles).includes(req.session.role)) throw fail(403, 'Read-only data.');
    const { changes = [], deletions = [] } = req.body;
    if (!Array.isArray(changes) || !Array.isArray(deletions) || changes.length + deletions.length > 1000) throw fail(400, 'Invalid batch.');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const saved = [];
      const postNotifications = [];
      // Owners whose cancellation count reached the suspension threshold during
      // this sync. They are suspended once, atomically, before the commit.
      const ownersToSuspend = new Set();
      for (const item of [...changes, ...deletions.map(x => ({ ...x, deleting: true }))]) {
        if (typeof item.id !== 'string' || !item.id || item.id.length > 250 || !Number.isInteger(item.version) || item.version < 0) throw fail(400, 'Invalid record.');
        const existing = (await client.query(`SELECT * FROM ${req.params.table} WHERE id=$1 FOR UPDATE`, [item.id])).rows[0];
        if (existing && ownOnly(p, req.session) && existing.owner_id !== req.session.account_id) throw fail(403, 'Access denied.');
        // Doctors own the health posts they create. Staff and system admins
        // retain clinic-wide moderation access, but one doctor cannot change
        // or delete another doctor's content through the generic sync API.
        if (req.params.table === 'health_posts' && existing && req.session.role === 'doctor' && existing.owner_id !== req.session.account_id) {
          throw fail(403, 'Only the author can change this post.');
        }
        if ((existing?.version || 0) !== item.version) throw fail(409, 'This record changed on another device. Reload before saving.');
        if (p.appendOnly && (existing || item.deleting)) throw fail(403, 'Audit entries cannot be changed or deleted.');
        if (item.deleting) {
          // Deleting a directory record removes the whole account: the login
          // (app_accounts), its sessions and device tokens, then the row.
          if (req.params.table === 'user_directory' && existing) {
            const accountId = existing.data.value?.id;
            if (accountId) {
              if (accountId === req.session.account_id) throw fail(400, 'You cannot delete your own administrator account.');
              await client.query('DELETE FROM app_sessions WHERE account_id=$1', [accountId]);
              await client.query('DELETE FROM device_tokens WHERE account_id=$1', [accountId]);
              await client.query('DELETE FROM app_accounts WHERE id=$1', [accountId]);
            }
          }
          await client.query(`DELETE FROM ${req.params.table} WHERE id=$1`, [item.id]);
          continue;
        }
        if (!item.data || typeof item.data !== 'object' || Array.isArray(item.data)) throw fail(400, 'Invalid record data.');
        if (typeof item.data.key !== 'string' || !item.data.key || !item.data.value || typeof item.data.value !== 'object' || Array.isArray(item.data.value)) throw fail(400, 'Invalid record data.');
        if (existing && existing.data.key !== item.data.key) throw fail(400, 'Record key cannot change.');
        // Keep the account identity in step with the doctor's public profile.
        // The clinic directory prefers the profile value, while full_name is
        // its fallback and is also returned with future login sessions.
        if (req.params.table === 'doctor_profiles') {
          const profileName = typeof item.data.value.name === 'string'
            ? item.data.value.name.trim()
            : '';
          if (!profileName || profileName.length > 200) throw fail(400, 'A valid doctor name is required.');
          item.data.value.name = profileName;
          await client.query(
            "UPDATE app_accounts SET full_name=$2 WHERE id=$1 AND role='doctor'",
            [req.session.account_id, profileName],
          );
        }
        let ownerId = existing?.owner_id || req.session.account_id;
        if (!existing && p.scope === 'owner' && req.session.role !== 'petOwner' && item.ownerId) {
          const target = await client.query("SELECT id FROM app_accounts WHERE id=$1 AND role='petOwner'", [item.ownerId]);
          if (!target.rowCount) throw fail(400, 'Owner account not found.');
          ownerId = item.ownerId;
        }
        if (req.params.table === 'user_directory') {
          const value = item.data.value;
          await syncUserDirectoryAccount(client, value, existing, req.session.account_id);
        }
        // Reject a second active booking for the same owner, pet, date and
        // time. The transaction locks make this authoritative even when two
        // devices submit the same booking concurrently. Stable pet IDs are
        // preferred, with a name/species/breed fallback for older records.
        let appointmentSlotLocked = false;
        if (duplicateProtectedBookingTables.has(req.params.table)) {
          const value = item.data.value || {};
          const previous = existing?.data?.value || {};
          const date = bookingDate(value);
          const time = bookingTime(value);
          const hasPet = Boolean(bookingPetStableId(value) || normalizedBookingText(value.pet?.name));
          const shouldCheckDuplicate = activeBooking(req.params.table, value) &&
            date && time && hasPet && (
              !existing ||
              !activeBooking(req.params.table, previous) ||
              bookingDate(previous) !== date ||
              bookingTime(previous) !== time ||
              !sameBookingPet(previous, value)
            );
          if (shouldCheckDuplicate) {
            if (req.params.table === 'appointments') {
              await client.query(
                'SELECT pg_advisory_xact_lock(hashtext($1))',
                [`booking-slot:${req.params.table}:${date}:${time}`],
              );
              appointmentSlotLocked = true;
            }
            await client.query(
              'SELECT pg_advisory_xact_lock(hashtext($1))',
              [`booking-owner:${req.params.table}:${ownerId}`],
            );
            const candidates = (await client.query(
              `SELECT data FROM ${req.params.table}
               WHERE id<>$1 AND owner_id=$2
                 AND LEFT(data->'value'->>'date',10)=$3
                 AND data->'value'->>'time'=$4`,
              [item.id, ownerId, date, time],
            )).rows;
            const duplicate = candidates.some(row => {
              const candidate = row.data?.value || {};
              return activeBooking(req.params.table, candidate) && sameBookingPet(candidate, value);
            });
            if (duplicate) {
              throw fail(409, 'This pet already has an active booking at that date and time.');
            }
          }
        }
        // Appointment booking rules are authoritative on the server so they
        // cannot be bypassed by a modified client:
        //  1. A veterinarian/date/time slot may hold at most APPOINTMENT_SLOT_CAPACITY
        //     active (non-cancelled) bookings. Cancelling a booking frees the
        //     slot immediately because cancelled rows are never counted.
        //  2. A pet owner whose cancellations reach the suspension threshold is
        //     suspended automatically (login disabled, sessions revoked).
        if (req.params.table === 'appointments') {
          const value = item.data.value || {};
          const status = String(value.status || '');
          const previousStatus = String(existing?.data?.value?.status || '');
          const slotKey = {
            date: String(value.date || '').slice(0, 10),
            time: String(value.time || ''),
          };
          // Enforce slot capacity whenever a booking is (or becomes) active for
          // a slot: on creation, or when an existing row is moved into an active
          // status / re-slotted. The slot is clinic-wide, so bookings for every
          // doctor at the same date/time share the same capacity. Cancelled
          // bookings are exempt.
          const isActiveBooking = status !== 'Cancelled';
          const slotChanged = existing && (
            String(existing.data.value.date || '').slice(0, 10) !== slotKey.date ||
            String(existing.data.value.time || '') !== slotKey.time
          );
          const becameActive = existing && previousStatus === 'Cancelled' && isActiveBooking;
          if (isActiveBooking && slotKey.date && slotKey.time &&
              (!existing || slotChanged || becameActive)) {
            if (!appointmentSlotLocked) {
              await client.query(
                'SELECT pg_advisory_xact_lock(hashtext($1))',
                [`booking-slot:${req.params.table}:${slotKey.date}:${slotKey.time}`],
              );
            }
            const occupancy = (await client.query(
              `SELECT COUNT(*)::int AS count FROM appointments
               WHERE id<>$1
                 AND LEFT(data->'value'->>'date',10)=$2
                 AND data->'value'->>'time'=$3
                 AND COALESCE(data->'value'->>'status','')<>'Cancelled'`,
              [item.id, slotKey.date, slotKey.time],
            )).rows[0].count;
            if (occupancy >= APPOINTMENT_SLOT_CAPACITY) {
              throw fail(409, 'That time slot is fully booked. Please choose another time.');
            }
          }
          // Auto-suspend when an owner's booking is newly cancelled.
          const newlyCancelled = status === 'Cancelled' && previousStatus !== 'Cancelled';
          const cancelledByOwner = String(value.cancellation?.initiatedBy || 'owner') === 'owner';
          if (newlyCancelled && cancelledByOwner) {
            // Count this owner's cancelled appointments, including the one being
            // saved in this request (it may be an insert or an update).
            const priorCancellations = (await client.query(
              `SELECT COUNT(*)::int AS count FROM appointments
               WHERE owner_id=$1 AND id<>$2
                 AND data->'value'->>'status'='Cancelled'
                 AND COALESCE(data->'value'->'cancellation'->>'initiatedBy','owner')='owner'`,
              [ownerId, item.id],
            )).rows[0].count;
            if (priorCancellations + 1 >= APPOINTMENT_CANCELLATION_SUSPEND_THRESHOLD) {
              ownersToSuspend.add(ownerId);
            }
          }
          if (newlyCancelled && !cancelledByOwner) {
            const petName = String(value.pet?.name || 'Your pet');
            const reason = String(value.cancellation?.reason || '').trim();
            const title = 'Appointment cancelled by clinic';
            const message = reason
              ? `${petName}'s appointment was cancelled by the clinic. Reason: ${reason}`
              : `${petName}'s appointment was cancelled by the clinic.`;
            await saveOwnerNotification(client, ownerId, title, message);
            postNotifications.push({ ownerId, title, message });
          }
        }
        if (existing) {
          saved.push((await client.query(`UPDATE ${req.params.table} SET data=$2,version=version+1,updated_at=NOW() WHERE id=$1 RETURNING id,owner_id,data,version`, [item.id, item.data])).rows[0]);
        } else {
          saved.push((await client.query(`INSERT INTO ${req.params.table}(id,owner_id,data) VALUES($1,$2,$3) RETURNING id,owner_id,data,version`, [item.id, ownerId, item.data])).rows[0]);
          if (req.params.table === 'health_posts' && item.data.value.status !== 'scheduled' && item.data.value.status !== 'archived') {
            const owners = (await client.query("SELECT id FROM app_accounts WHERE role='petOwner' AND active=TRUE")).rows;
            const title = `New ${item.data.value.category || 'pet health'} post`;
            const message = `${item.data.value.authorName || 'A clinic veterinarian'} published “${item.data.value.title || 'a new post'}”.`;
            for (const owner of owners) {
              await saveOwnerNotification(client, owner.id, title, message);
              postNotifications.push({ ownerId: owner.id, title, message });
            }
          }
        }
      }
      // Apply automatic suspension for owners who hit the cancellation limit.
      // Disabling the account blocks future logins (the login query and the
      // session guard both require active=TRUE); clearing sessions signs the
      // owner out of any device currently holding a token. The public user
      // directory view reflects active=FALSE as a "suspended" status.
      const suspendedOwners = [...ownersToSuspend];
      for (const suspendOwnerId of suspendedOwners) {
        await client.query("UPDATE app_accounts SET active=FALSE WHERE id=$1 AND role='petOwner'", [suspendOwnerId]);
        await client.query('DELETE FROM app_sessions WHERE account_id=$1', [suspendOwnerId]);
      }
      await client.query('COMMIT');
      for (const suspendOwnerId of suspendedOwners) {
        broadcastChange('user_directory', { ownerId: suspendOwnerId });
      }
      // Notify connected clients that this table changed so they refresh live
      // (drives the real-time queue). Only emit when something actually changed.
      if (changes.length || deletions.length) {
        broadcastChange(req.params.table);
        if (postNotifications.length) broadcastChange('owner_notifications');
        // clinic_directory is a computed view over accounts + doctor profiles.
        // Refresh staff/owner doctor pickers as soon as availability changes.
        if (req.params.table === 'doctor_profiles' || req.params.table === 'staff_profiles' || req.params.table === 'user_directory') {
          broadcastChange('clinic_directory');
        }
      }
      for (const notice of postNotifications) {
        await sendToAccount(pool, notice.ownerId, {
          title: notice.title,
          body: notice.message,
          data: { type: 'health_post' },
        });
      }
      res.json({ records: saved });
    } catch (e) { await client.query('ROLLBACK'); if (e.code === '23505') throw fail(409, 'Record already exists. Reload before saving.'); throw e; }
    finally { client.release(); }
  }));
}
module.exports = { installApi, syncUserDirectoryAccount, findAccountByIdentifier };

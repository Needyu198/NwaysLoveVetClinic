const crypto = require('node:crypto');

const { pool } = require('./db');
const { sendToAccount } = require('./messaging');
const { broadcastChange } = require('./realtime');

const clinicTimeZone = () => process.env.CLINIC_TIME_ZONE || 'Asia/Bangkok';

/**
 * Finds appointments starting in the next 30 minutes and sends each owner one
 * durable in-app notification plus one FCM push. The database claim prevents
 * duplicate pushes when multiple API instances run at the same time.
 */
async function runAppointmentReminders(
  database = pool,
  now = new Date(),
  { sendPush = sendToAccount, broadcast = broadcastChange } = {},
) {
  const candidates = (
    await database.query(
      `SELECT a.id, a.owner_id,
          jsonb_extract_path(a.data::jsonb, 'value') AS appointment,
          slot.start_at
       FROM appointments a
       CROSS JOIN LATERAL (
         SELECT to_timestamp(
           substring(jsonb_extract_path_text(a.data::jsonb, 'value', 'date') from 1 for 10) || ' ' ||
             jsonb_extract_path_text(a.data::jsonb, 'value', 'time'),
           'YYYY-MM-DD HH12:MI AM'
         )::timestamp AT TIME ZONE $2 AS start_at
       ) slot
       LEFT JOIN LATERAL (
         SELECT jsonb_extract_path(data::jsonb, 'value') AS preferences
         FROM notification_settings
         WHERE owner_id=a.owner_id
         ORDER BY updated_at DESC LIMIT 1
       ) settings ON TRUE
       WHERE jsonb_extract_path_text(a.data::jsonb, 'value', 'status') IN ('Pending','Confirmed')
         AND jsonb_extract_path_text(
           a.data::jsonb,
           'value',
           'cancellation'
         ) IS NULL
         AND COALESCE(
           jsonb_extract_path_text(settings.preferences::jsonb, 'enabled')::boolean,
           TRUE
         )
         AND COALESCE(
           jsonb_extract_path_text(
             settings.preferences::jsonb,
             'appointments'
           )::boolean,
           TRUE
         )
         AND slot.start_at > $1::timestamptz
         AND slot.start_at <= $1::timestamptz + INTERVAL '30 minutes'
       ORDER BY slot.start_at
       LIMIT 100`,
      [now.toISOString(), clinicTimeZone()],
    )
  ).rows;

  let sent = 0;
  for (const row of candidates) {
    const client = await database.connect();
    let claimed = false;
    let title;
    let message;
    let appointmentId;
    try {
      await client.query('BEGIN');
      const claim = await client.query(
        `INSERT INTO appointment_reminders(
           appointment_id, owner_id, scheduled_for
         ) VALUES($1,$2,$3)
         ON CONFLICT DO NOTHING RETURNING appointment_id`,
        [row.id, row.owner_id, row.start_at],
      );
      if (!claim.rowCount) {
        await client.query('ROLLBACK');
        continue;
      }

      const appointment = row.appointment || {};
      const petName = String(appointment.pet?.name || 'Your pet');
      const time = String(appointment.time || 'soon');
      appointmentId = String(appointment.id || row.id);
      title = 'Appointment in 30 minutes';
      message = `${petName}'s appointment starts at ${time}. Please prepare to arrive at the clinic.`;
      const notificationId = `appointment-reminder:${crypto.randomUUID()}`;
      const value = {
        id: notificationId,
        title,
        message,
        createdAt: now.toISOString(),
        read: false,
      };
      await client.query(
        `INSERT INTO owner_notifications(id,owner_id,data)
         VALUES($1,$2,$3)`,
        [
          notificationId,
          row.owner_id,
          { key: `${row.owner_id}:${notificationId}`, value },
        ],
      );
      await client.query('COMMIT');
      claimed = true;
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Appointment reminder failed:', error.message);
    } finally {
      client.release();
    }
    if (!claimed) continue;

    broadcast('owner_notifications', { ownerId: row.owner_id });
    await sendPush(database, row.owner_id, {
      title,
      body: message,
      data: { type: 'appointment_reminder', appointmentId },
    });
    sent++;
  }
  return { checked: candidates.length, sent };
}

let timer;

function startAppointmentReminderScheduler({ intervalMs = 30_000 } = {}) {
  if (timer) return;
  const check = () =>
    runAppointmentReminders().catch((error) =>
      console.error('Appointment reminder scheduler failed:', error.message),
    );
  check();
  timer = setInterval(check, intervalMs);
  timer.unref?.();
}

function stopAppointmentReminderScheduler() {
  if (timer) clearInterval(timer);
  timer = undefined;
}

module.exports = {
  runAppointmentReminders,
  startAppointmentReminderScheduler,
  stopAppointmentReminderScheduler,
};

// Firebase Cloud Messaging (FCM) push delivery via the Firebase Admin SDK.
//
// This sends push notifications to a clinic account's registered devices
// (see device_tokens, populated by POST /devices/register).
//
// Credentials: set GOOGLE_APPLICATION_CREDENTIALS to the path of a Firebase
// service-account JSON, or set FIREBASE_SERVICE_ACCOUNT to the JSON contents.
// If neither is present, push is disabled gracefully (sendToAccount is a no-op)
// so the rest of the API keeps working in local dev.

let admin = null;
let initialized = false;
let enabled = false;

function init() {
  if (initialized) return;
  initialized = true;
  try {
    // Lazy require so the dependency is only loaded when configured.
    admin = require('firebase-admin');
    let credential;
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      credential = admin.credential.cert(
        JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT),
      );
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      credential = admin.credential.applicationDefault();
    } else {
      console.warn('FCM disabled: no Firebase service-account credentials set.');
      return;
    }
    if (admin.apps.length === 0) {
      admin.initializeApp({ credential });
    }
    enabled = true;
  } catch (e) {
    console.warn('FCM disabled:', e.message);
  }
}

/**
 * Send a push notification to every device registered to an account.
 * No-op (resolves) when FCM is not configured. Never throws.
 * @param {import('pg').Pool} pool
 * @param {string} accountId
 * @param {{ title: string, body: string, data?: Record<string,string> }} message
 */
async function sendToAccount(pool, accountId, message) {
  init();
  if (!enabled) return { sent: 0, disabled: true };
  try {
    const rows = (
      await pool.query('SELECT token FROM device_tokens WHERE account_id=$1', [accountId])
    ).rows;
    const tokens = rows.map(r => r.token);
    if (tokens.length === 0) return { sent: 0 };
    const res = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: message.title, body: message.body },
      data: message.data || {},
    });
    // Clean up tokens FCM reports as invalid/unregistered.
    const stale = [];
    res.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error && r.error.code;
        if (code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-registration-token') {
          stale.push(tokens[i]);
        }
      }
    });
    if (stale.length) {
      await pool.query('DELETE FROM device_tokens WHERE token = ANY($1)', [stale]);
    }
    return { sent: res.successCount, failed: res.failureCount };
  } catch (e) {
    console.error('FCM send failed:', e.message);
    return { sent: 0, error: e.message };
  }
}

function isEnabled() {
  init();
  return enabled;
}

module.exports = { sendToAccount, isEnabled };

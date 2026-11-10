const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const QRCode = require('qrcode');
const PDFDocument = require('pdfkit');
const { resources } = require('./resources');
const { broadcastChange } = require('./realtime');
const { sendToAccount } = require('./messaging');
const { resetEmailConfigured, sendPasswordResetEmail, sendReceiptEmail } = require('./passwordResetEmail');
const hash = token => crypto.createHash('sha256').update(token).digest('hex');
const fail = (status, message) => Object.assign(new Error(message), { status });
const MMQR_CURRENCY = 'MMK';
const paymentActor = session => ({
  actorId: session.account_id,
  actorRole: session.role,
});
const paymentAuditEvent = ({ actorId, actorRole }, action, fromStatus, toStatus, details, now) => ({
  id: `PAE-${crypto.randomUUID()}`,
  at: now.toISOString(),
  actorId,
  actorRole,
  action,
  fromStatus,
  toStatus,
  details,
});
const paymentCopy = payment => structuredClone(payment || {});
async function renderMmqrQr(payment) {
  const value = paymentCopy(payment);
  if (!value.mmqr?.qrPayload) return value;
  value.mmqr.payloadHash = hash(value.mmqr.qrPayload);
  value.mmqr.qrImageDataUrl = await QRCode.toDataURL(value.mmqr.qrPayload, {
    errorCorrectionLevel: 'M',
    margin: 2,
    width: 360,
  });
  return value;
}
async function prepareMmqrPayment(payment, request = fetch) {
  const endpoint = String(process.env.MMQR_PROVIDER_QR_ENDPOINT || '').trim();
  if (!endpoint) return renderMmqrQr({
    ...payment,
    mmqr: { ...payment.mmqr, providerMode: 'development_payload' },
  });
  if (!process.env.MMQR_PROVIDER_API_KEY || !process.env.MMQR_MERCHANT_ID) {
    throw fail(503, 'MMQR provider credentials are incomplete.');
  }
  const response = await request(endpoint, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.MMQR_PROVIDER_API_KEY}`,
      'Content-Type': 'application/json',
      'Idempotency-Key': payment.mmqr.attemptId,
    },
    body: JSON.stringify({
      merchantId: process.env.MMQR_MERCHANT_ID,
      invoiceId: payment.id,
      reference: payment.mmqr.reference,
      amount: payment.mmqr.amount,
      currency: payment.mmqr.currency,
      expiresAt: payment.mmqr.expiresAt,
    }),
    signal: AbortSignal.timeout(10_000),
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok || typeof result.qrPayload !== 'string' || !result.qrPayload) {
    throw fail(503, 'The MMQR acquiring provider could not create a payment QR.');
  }
  if (result.reference && result.reference !== payment.mmqr.reference) {
    throw fail(503, 'The MMQR provider returned a mismatched payment reference.');
  }
  return renderMmqrQr({
    ...payment,
    mmqr: {
      ...payment.mmqr,
      qrPayload: result.qrPayload,
      providerAttemptId: String(result.providerAttemptId || ''),
      providerMode: 'acquirer_api',
    },
  });
}
function createMmqrPayment(payment, actor, options = {}) {
  const value = paymentCopy(payment);
  const now = options.now || new Date();
  if (value.status === 'Paid') throw fail(409, 'A paid invoice cannot start another MMQR payment.');
  if (!['Unpaid', 'Failed'].includes(String(value.status || 'Unpaid'))) {
    throw fail(409, 'MMQR requires a fully unpaid invoice with a known outstanding amount.');
  }
  if (value.status === 'Pending' && value.mmqr?.status === 'Pending') {
    throw fail(409, 'This invoice already has a pending MMQR payment.');
  }
  const amount = Number(value.amount);
  if (!Number.isInteger(amount) || amount <= 0) throw fail(400, 'The invoice amount must be a positive MMK amount.');
  const reference = options.reference || `MMQR-${crypto.randomBytes(8).toString('hex').toUpperCase()}`;
  const attemptId = options.attemptId || `MMA-${crypto.randomUUID()}`;
  const expiresAt = new Date(now.getTime() + 15 * 60 * 1000);
  const previous = String(value.status || 'Unpaid');
  value.status = 'Pending';
  value.paymentMethod = 'MMQR';
  value.mmqrAttempts = [
    ...(Array.isArray(value.mmqrAttempts) ? value.mmqrAttempts : []),
    ...(value.mmqr ? [{ ...value.mmqr }] : []),
  ];
  value.mmqr = {
    attemptId,
    reference,
    merchantId: String(process.env.MMQR_MERCHANT_ID || ''),
    merchantName: String(process.env.MMQR_MERCHANT_NAME || "Nway's Love Vet Clinic"),
    amount,
    currency: MMQR_CURRENCY,
    status: 'Pending',
    createdAt: now.toISOString(),
    expiresAt: expiresAt.toISOString(),
    // This payload is handed to the configured MMQR acquiring integration.
    // It is not treated as evidence of settlement.
    qrPayload: `MMQR|merchant=${encodeURIComponent(String(process.env.MMQR_MERCHANT_ID || 'UNCONFIGURED'))}|invoice=${encodeURIComponent(String(value.id || ''))}|amount=${amount}|currency=${MMQR_CURRENCY}|reference=${reference}|expires=${encodeURIComponent(expiresAt.toISOString())}`,
  };
  value.auditTrail = [...(Array.isArray(value.auditTrail) ? value.auditTrail : []), paymentAuditEvent(
    actor, 'mmqr.created', previous, 'Pending', { attemptId, reference, amount, currency: MMQR_CURRENCY }, now,
  )];
  return value;
}
function expireMmqrPayment(payment, actor, options = {}) {
  const value = paymentCopy(payment);
  const now = options.now || new Date();
  if (value.status !== 'Pending' || value.mmqr?.status !== 'Pending') throw fail(409, 'Only a pending MMQR attempt can expire.');
  if (!options.force && new Date(value.mmqr.expiresAt).getTime() > now.getTime()) throw fail(409, 'This MMQR attempt has not expired.');
  value.status = 'Unpaid';
  value.mmqr = { ...value.mmqr, status: 'Expired', expiredAt: now.toISOString() };
  value.auditTrail = [...(Array.isArray(value.auditTrail) ? value.auditTrail : []), paymentAuditEvent(
    actor, 'mmqr.expired', 'Pending', 'Unpaid', { attemptId: value.mmqr.attemptId, reference: value.mmqr.reference }, now,
  )];
  return value;
}
function markMmqrDisplayed(payment, actor, options = {}) {
  const value = paymentCopy(payment);
  if (!value.mmqr?.attemptId) throw fail(409, 'No MMQR attempt is available to display.');
  const alreadyRecorded = (value.auditTrail || []).some(event =>
    event.action === 'mmqr.displayed' && event.details?.attemptId === value.mmqr.attemptId);
  if (alreadyRecorded) return value;
  const now = options.now || new Date();
  value.auditTrail = [...(value.auditTrail || []), paymentAuditEvent(
    actor,
    'mmqr.displayed',
    value.status,
    value.status,
    { attemptId: value.mmqr.attemptId, reference: value.mmqr.reference },
    now,
  )];
  return value;
}
function validatePendingMmqr(payment, input, now = new Date(), { allowExpired = false } = {}) {
  if (payment.status === 'Paid') throw fail(409, 'This invoice is already settled and cannot be finalized twice.');
  const pending = payment.status === 'Pending' && payment.mmqr?.status === 'Pending';
  const expired = payment.status === 'Unpaid' && payment.mmqr?.status === 'Expired';
  if (!pending && !(allowExpired && expired)) throw fail(409, 'There is no pending MMQR payment to settle.');
  if (String(input.reference || '') !== payment.mmqr.reference) throw fail(409, 'The MMQR reference does not match this invoice.');
  if (Number(input.amount) !== Number(payment.mmqr.amount) || Number(input.amount) !== Number(payment.amount)) {
    throw fail(409, 'The settlement amount does not match this invoice.');
  }
  if (!allowExpired && new Date(payment.mmqr.expiresAt).getTime() <= now.getTime()) {
    throw fail(409, 'This MMQR attempt has expired. Send late settlement to reconciliation.');
  }
}
async function expirePendingMmqrPayments(database) {
  const client = await database.connect();
  const changedOwners = new Set();
  let count = 0;
  try {
    await client.query('BEGIN');
    const rows = (await client.query(
      `SELECT * FROM payments
       WHERE data->'value'->>'status'='Pending'
         AND data->'value'->'mmqr'->>'status'='Pending'
         AND (data->'value'->'mmqr'->>'expiresAt')::timestamptz<=NOW()
       ORDER BY updated_at FOR UPDATE SKIP LOCKED LIMIT 100`,
    )).rows;
    for (const row of rows) {
      const previous = row.data.value;
      const next = expireMmqrPayment(previous, { actorId: 'system:mmqr-expiry', actorRole: 'system' });
      await appendPaymentEvents(client, row, previous, next);
      await client.query(
        'UPDATE payments SET data=$2,version=version+1,updated_at=NOW() WHERE id=$1',
        [row.id, { ...row.data, value: next }],
      );
      if (next.orderId) {
        await client.query(
          `UPDATE product_orders SET
             data=jsonb_set(jsonb_set(data,'{value,paymentStatus}',to_jsonb('Unpaid'::text),true),'{value,mmqr}',$3::jsonb,true),
             version=version+1,updated_at=NOW()
           WHERE owner_id=$1 AND data->'value'->>'id'=$2`,
          [row.owner_id, next.orderId, JSON.stringify(next.mmqr)],
        );
      }
      changedOwners.add(row.owner_id);
      count += 1;
    }
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
  if (count) {
    broadcastChange('payments');
    for (const ownerId of changedOwners) broadcastChange('product_orders', { ownerId });
  }
  return count;
}
function settleMmqrPayment(payment, input, actor, options = {}) {
  const value = paymentCopy(payment);
  const now = options.now || new Date();
  validatePendingMmqr(value, input, now);
  const providerTransactionId = String(input.providerTransactionId || '').trim();
  if (!providerTransactionId || providerTransactionId.length > 200) throw fail(400, 'A valid provider transaction ID is required.');
  value.status = 'Paid';
  value.paidAt = now.toISOString();
  value.mmqr = { ...value.mmqr, status: 'Settled', settledAt: now.toISOString(), providerTransactionId };
  value.settlement = { type: 'provider_verified', providerTransactionId, verifiedAt: now.toISOString() };
  value.auditTrail = [...(Array.isArray(value.auditTrail) ? value.auditTrail : []), paymentAuditEvent(
    actor, 'mmqr.provider_settled', 'Pending', 'Paid', {
      reference: value.mmqr.reference,
      amount: value.amount,
      currency: MMQR_CURRENCY,
      providerTransactionId,
    }, now,
  ), paymentAuditEvent(actor, 'payment.settled', 'Pending', 'Paid', { method: 'MMQR', amount: value.amount }, now)];
  return value;
}
function reconcileMmqrPayment(payment, input, actor, options = {}) {
  const value = paymentCopy(payment);
  const now = options.now || new Date();
  validatePendingMmqr(value, input, now, { allowExpired: true });
  const previousStatus = value.status;
  const receiptReference = String(input.receiptReference || '').trim();
  const note = String(input.note || '').trim();
  if (!receiptReference || receiptReference.length > 200) throw fail(400, 'A valid receipt reference is required.');
  if (note.length < 10 || note.length > 1000) throw fail(400, 'A reconciliation note of at least 10 characters is required.');
  value.status = 'Paid';
  value.paidAt = now.toISOString();
  value.mmqr = { ...value.mmqr, status: 'Reconciled', settledAt: now.toISOString() };
  value.settlement = { type: 'staff_reconciliation', receiptReference, note, verifiedAt: now.toISOString(), verifiedBy: actor.actorId };
  value.auditTrail = [...(Array.isArray(value.auditTrail) ? value.auditTrail : []), paymentAuditEvent(
    actor, 'mmqr.staff_reconciled', previousStatus, 'Paid', {
      reference: value.mmqr.reference,
      amount: value.amount,
      currency: MMQR_CURRENCY,
      receiptReference,
      note,
    }, now,
  ), paymentAuditEvent(actor, 'payment.settled', previousStatus, 'Paid', { method: 'MMQR', amount: value.amount }, now)];
  return value;
}
function cancelMmqrPayment(payment, input, actor, options = {}) {
  const value = paymentCopy(payment);
  if (value.status !== 'Pending' || value.mmqr?.status !== 'Pending') throw fail(409, 'Only a pending MMQR payment can be cancelled.');
  const reason = String(input.reason || '').trim();
  if (reason.length < 5 || reason.length > 500) throw fail(400, 'A cancellation reason is required.');
  const now = options.now || new Date();
  value.status = 'Unpaid';
  value.mmqr = { ...value.mmqr, status: 'Cancelled', cancelledAt: now.toISOString() };
  value.auditTrail = [...(Array.isArray(value.auditTrail) ? value.auditTrail : []), paymentAuditEvent(
    actor, 'mmqr.cancelled', 'Pending', 'Unpaid', { reference: value.mmqr.reference, reason }, now,
  )];
  return value;
}
function createCashPayment(payment, actor, options = {}) {
  const value = paymentCopy(payment);
  const now = options.now || new Date();
  const amount = Number(value.amount);
  if (!Number.isInteger(amount) || amount <= 0) throw fail(400, 'The invoice amount must be a positive MMK amount.');
  value.status = 'Unpaid';
  value.paymentMethod = 'Cash';
  value.auditTrail = [...(Array.isArray(value.auditTrail) ? value.auditTrail : []), paymentAuditEvent(
    actor, 'cash.selected', String(payment.status || 'Unpaid'), 'Unpaid', { amount, currency: MMQR_CURRENCY }, now,
  )];
  return value;
}
function collectCashPayment(payment, input, actor, options = {}) {
  const value = paymentCopy(payment);
  if (value.status === 'Paid') throw fail(409, 'This invoice is already settled and cannot be finalized twice.');
  if (value.status !== 'Unpaid' || value.paymentMethod !== 'Cash') throw fail(409, 'This invoice is not awaiting cash collection.');
  const tenderedAmount = Number(input.tenderedAmount);
  const amount = Number(value.amount);
  if (!Number.isInteger(tenderedAmount) || tenderedAmount < amount) throw fail(400, 'Cash tendered must cover the invoice amount.');
  const receiptReference = String(input.receiptReference || '').trim();
  if (!receiptReference || receiptReference.length > 200) throw fail(400, 'A receipt reference is required.');
  const now = options.now || new Date();
  const changeAmount = tenderedAmount - amount;
  value.status = 'Paid';
  value.paidAt = now.toISOString();
  value.settlement = {
    type: 'cash_collected',
    receiptReference,
    tenderedAmount,
    changeAmount,
    verifiedAt: now.toISOString(),
    verifiedBy: actor.actorId,
  };
  value.auditTrail = [...(Array.isArray(value.auditTrail) ? value.auditTrail : []), paymentAuditEvent(
    actor, 'cash.collected', 'Unpaid', 'Paid', { amount, tenderedAmount, changeAmount, receiptReference, currency: MMQR_CURRENCY }, now,
  ), paymentAuditEvent(actor, 'payment.settled', 'Unpaid', 'Paid', { method: 'Cash', amount }, now)];
  return value;
}
const mmqrProofPayload = ({ reference, amount, providerTransactionId }) =>
  `${reference}|${amount}|${providerTransactionId}|confirmed`;
const verifyMmqrProof = (input, proof, secret) => {
  if (!secret) throw fail(503, 'MMQR provider verification is not configured. Use documented staff reconciliation instead.');
  const expected = crypto.createHmac('sha256', secret).update(mmqrProofPayload(input)).digest('hex');
  const supplied = String(proof || '').trim().toLowerCase();
  const left = Buffer.from(expected, 'utf8');
  const right = Buffer.from(supplied, 'utf8');
  if (left.length !== right.length || !crypto.timingSafeEqual(left, right)) throw fail(403, 'MMQR settlement proof is invalid.');
};
const mmqrWebhookProofPayload = input => [
  input.merchantId,
  input.invoiceId,
  input.reference,
  input.amount,
  input.providerTransactionId,
  input.status,
].join('|');
const verifyMmqrWebhook = (input, proof, secret) => {
  if (!secret) throw fail(503, 'MMQR webhook verification is not configured.');
  if (!process.env.MMQR_MERCHANT_ID || input.merchantId !== process.env.MMQR_MERCHANT_ID) {
    throw fail(403, 'MMQR merchant identity is invalid.');
  }
  const expected = crypto.createHmac('sha256', secret).update(mmqrWebhookProofPayload(input)).digest('hex');
  const supplied = String(proof || '').trim().toLowerCase();
  const left = Buffer.from(expected, 'utf8');
  const right = Buffer.from(supplied, 'utf8');
  if (left.length !== right.length || !crypto.timingSafeEqual(left, right)) throw fail(403, 'MMQR webhook signature is invalid.');
};
async function createPaymentReceipt(client, paymentRow, payment, actor) {
  if (payment.status !== 'Paid') return null;
  const existing = (await client.query(
    'SELECT * FROM payment_receipts WHERE payment_id=$1',
    [payment.id],
  )).rows[0];
  if (existing) return existing;
  const sequence = (await client.query("SELECT nextval('payment_receipt_number_seq') AS number")).rows[0].number;
  const receiptNumber = `RCP-${new Date().getUTCFullYear()}-${String(sequence).padStart(6, '0')}`;
  const publicToken = crypto.randomBytes(24).toString('base64url');
  let order = null;
  if (payment.orderId) {
    order = (await client.query(
      `SELECT data->'value' AS value FROM product_orders
       WHERE owner_id=$1 AND data->'value'->>'id'=$2 LIMIT 1`,
      [paymentRow.owner_id, payment.orderId],
    )).rows[0]?.value || null;
  }
  const verificationUrl = `${String(process.env.PUBLIC_BASE_URL || 'http://127.0.0.1:5050').replace(/\/$/, '')}/receipts/verify/${publicToken}`;
  const data = {
    receiptNumber,
    paymentId: payment.id,
    invoiceId: payment.id,
    orderId: payment.orderId || '',
    customerName: payment.owner || order?.ownerName || 'Registered owner',
    items: order?.items || [],
    subtotal: Number(payment.amount),
    discount: 0,
    total: Number(payment.amount),
    currency: MMQR_CURRENCY,
    paymentMethod: payment.paymentMethod,
    mmqrReference: payment.mmqr?.reference || '',
    providerTransactionId: payment.settlement?.providerTransactionId || '',
    settlementType: payment.settlement?.type || '',
    paidAt: payment.paidAt,
    verifiedBy: actor.actorId,
    verificationUrl,
    clinic: {
      name: "Nway's Love Vet Clinic",
      phone: process.env.CLINIC_PHONE || '',
      address: process.env.CLINIC_ADDRESS || '',
    },
  };
  const row = (await client.query(
    `INSERT INTO payment_receipts(id,payment_id,owner_id,receipt_number,public_token,data)
     VALUES($1,$2,$3,$4,$5,$6) RETURNING *`,
    [`receipt:${receiptNumber}`, payment.id, paymentRow.owner_id, receiptNumber, publicToken, data],
  )).rows[0];
  return row;
}
async function appendPaymentEvents(client, paymentRow, previous, next) {
  const existingIds = new Set((previous.auditTrail || []).map(event => event.id));
  for (const event of next.auditTrail || []) {
    if (existingIds.has(event.id)) continue;
    await client.query(
      `INSERT INTO payment_audit_events(id,payment_id,owner_id,event)
       VALUES($1,$2,$3,$4) ON CONFLICT(id) DO NOTHING`,
      [event.id, next.id, paymentRow.owner_id, event],
    );
  }
}
async function appendMmqrAttempts(client, paymentRow, previous, next) {
  const previousIds = new Set([
    previous.mmqr?.attemptId,
    ...(previous.mmqrAttempts || []).map(attempt => attempt.attemptId),
  ].filter(Boolean));
  const attempts = [next.mmqr, ...(next.mmqrAttempts || [])].filter(Boolean);
  for (const attempt of attempts) {
    if (!attempt.attemptId || previousIds.has(attempt.attemptId)) continue;
    await client.query(
      `INSERT INTO mmqr_payment_attempts(attempt_id,payment_id,owner_id,reference,payload_hash,data)
       VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(attempt_id) DO NOTHING`,
      [attempt.attemptId, next.id, paymentRow.owner_id, attempt.reference, attempt.payloadHash || null, attempt],
    );
  }
}
const publicReceipt = row => ({
  valid: true,
  receiptNumber: row.data.receiptNumber,
  paidAmount: row.data.total,
  currency: row.data.currency,
  paidAt: row.data.paidAt,
  paymentMethod: row.data.paymentMethod,
  invoiceStatus: 'Paid',
});
async function receiptPdfBuffer(receipt) {
  const verificationQr = await QRCode.toBuffer(receipt.verificationUrl, { width: 150, margin: 1 });
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 50 });
    const chunks = [];
    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    doc.fontSize(20).text(receipt.clinic?.name || "Nway's Love Vet Clinic", { align: 'center' });
    doc.fontSize(11).text(receipt.clinic?.address || '', { align: 'center' });
    doc.moveDown().fontSize(16).text('PAYMENT RECEIPT', { align: 'center' });
    doc.moveDown().fontSize(11);
    const rows = [
      ['Receipt', receipt.receiptNumber], ['Order', receipt.orderId || '—'],
      ['Customer', receipt.customerName], ['Payment', receipt.paymentMethod],
      ['Reference', receipt.mmqrReference || receipt.providerTransactionId || '—'],
      ['Paid at', receipt.paidAt],
    ];
    for (const [label, value] of rows) doc.text(`${label}: ${value}`);
    doc.moveDown();
    for (const item of receipt.items || []) {
      doc.text(`${item.quantity} × ${item.name}`, { continued: true });
      doc.text(`${Number(item.unitPrice) * Number(item.quantity)} ${receipt.currency}`, { align: 'right' });
    }
    doc.moveDown().fontSize(14).text(`Total: ${receipt.total} ${receipt.currency}`, { align: 'right' });
    doc.moveDown().image(verificationQr, { fit: [120, 120], align: 'center' });
    doc.fontSize(9).text('Scan to verify this receipt.', { align: 'center' });
    doc.end();
  });
}
async function processReceiptDeliveryJobs(database, deliver = sendReceiptEmail) {
  const claimed = (await database.query(
    `UPDATE receipt_delivery_jobs SET status='sending',attempts=attempts+1
     WHERE id IN (
       SELECT id FROM receipt_delivery_jobs
       WHERE status IN ('pending','retry') AND next_attempt_at<=NOW()
       ORDER BY created_at FOR UPDATE SKIP LOCKED LIMIT 10
     ) RETURNING *`,
  )).rows;
  for (const job of claimed) {
    try {
      const receiptRow = (await database.query(
        'SELECT * FROM payment_receipts WHERE receipt_number=$1',
        [job.receipt_number],
      )).rows[0];
      if (!receiptRow) throw new Error('Receipt no longer exists.');
      const receipt = {
        ...receiptRow.data,
        pdfUrl: `${String(process.env.PUBLIC_BASE_URL || 'http://127.0.0.1:5050').replace(/\/$/, '')}/receipts/${receiptRow.public_token}/pdf`,
      };
      await deliver({ to: job.email, name: job.recipient_name, receipt });
      await database.query("UPDATE receipt_delivery_jobs SET status='sent',last_error=NULL WHERE id=$1", [job.id]);
      await database.query(
        "INSERT INTO receipt_delivery_events(receipt_number,event,metadata) VALUES($1,'receipt.emailed',$2)",
        [job.receipt_number, { emailHash: hash(job.email.toLowerCase()) }],
      );
    } catch (error) {
      const terminal = job.attempts >= 5;
      await database.query(
        `UPDATE receipt_delivery_jobs SET status=$2,last_error=$3,
           next_attempt_at=NOW()+($4::text || ' minutes')::interval WHERE id=$1`,
        [job.id, terminal ? 'failed' : 'retry', String(error.message).slice(0, 500), Math.min(60, 2 ** job.attempts)],
      );
      await database.query(
        "INSERT INTO receipt_delivery_events(receipt_number,event,metadata) VALUES($1,'receipt.email_failed',$2)",
        [job.receipt_number, { attempt: job.attempts, terminal }],
      );
    }
  }
  return claimed.length;
}
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
const bookingTimeMinutes = value => {
  const match = String(value || '').trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (!match) return null;
  const hour = Number(match[1]) % 12 + (match[3].toUpperCase() === 'PM' ? 12 : 0);
  return hour * 60 + Number(match[2]);
};
const bookingDuration = value => Math.max(1, Number(value?.service?.durationMinutes) || 60);
const bookingIntervalsOverlap = (left, right) => {
  const leftStart = bookingTimeMinutes(left?.time);
  const rightStart = bookingTimeMinutes(right?.time);
  if (leftStart === null || rightStart === null) return false;
  return leftStart < rightStart + bookingDuration(right) &&
    leftStart + bookingDuration(left) > rightStart;
};
const sameAppointmentDoctor = (left, right) => {
  const leftId = normalizedBookingText(left?.veterinarianId);
  const rightId = normalizedBookingText(right?.veterinarianId);
  return leftId && rightId
    ? leftId === rightId
    : normalizedBookingText(left?.veterinarian) === normalizedBookingText(right?.veterinarian);
};
const appointmentScheduleError = ({ profile, date, time, durationMinutes }) => {
  const startMinutes = bookingTimeMinutes(time);
  if (startMinutes === null || startMinutes < 8 * 60 ||
      startMinutes + durationMinutes > 19 * 60) {
    return 'That appointment is outside clinic hours. Please choose another time.';
  }
  if (!profile) return null;
  if (profile.acceptingAppointments === false) {
    return 'That veterinarian is not accepting appointments.';
  }
  const leaveDates = Array.isArray(profile.leaveDates) ? profile.leaveDates : [];
  if (leaveDates.some(leave => String(leave).slice(0, 10) === date)) {
    return 'That veterinarian is on leave. Please choose another date.';
  }
  const schedule = profile.schedule && typeof profile.schedule === 'object'
    ? profile.schedule
    : {};
  if (!Object.keys(schedule).length) return null;
  const weekday = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday'][
    new Date(`${date}T00:00:00Z`).getUTCDay()
  ];
  const day = schedule[weekday];
  const overlapsBreak = day?.breakStartMinutes != null && day?.breakEndMinutes != null &&
    startMinutes < Number(day.breakEndMinutes) &&
    startMinutes + durationMinutes > Number(day.breakStartMinutes);
  if (!day?.isWorking || startMinutes < Number(day.startMinutes) ||
      startMinutes + durationMinutes > Number(day.endMinutes) || overlapsBreak) {
    return 'That time is outside the veterinarian\'s working schedule.';
  }
  return null;
};
async function reserveProductOrderInventory(client, order, orderId) {
  const requestedPaymentMethod = ['MMQR', 'Cash'].includes(order.paymentMethod)
    ? order.paymentMethod
    : 'Pay at clinic';
  const requestedPaymentTiming = order.paymentTiming === 'Pay online'
    ? 'Pay online'
    : 'Pay at clinic';
  if (requestedPaymentTiming === 'Pay online' && requestedPaymentMethod !== 'MMQR') {
    throw fail(400, 'Online checkout must use MMQR.');
  }
  if (!Array.isArray(order.items) || order.items.length < 1 || order.items.length > 50) {
    throw fail(400, 'An order must contain between 1 and 50 products.');
  }
  const requested = new Map();
  for (const item of order.items) {
    const inventoryId = String(item?.inventoryId || '').trim();
    const quantity = Number(item?.quantity);
    if (!inventoryId || !Number.isInteger(quantity) || quantity <= 0 || quantity > 1000) {
      throw fail(400, 'Invalid product order quantity.');
    }
    requested.set(inventoryId, (requested.get(inventoryId) || 0) + quantity);
  }
  const verifiedItems = [];
  let total = 0;
  const now = new Date();
  for (const [inventoryId, quantity] of requested) {
    const row = (await client.query(
      `SELECT * FROM inventory WHERE data->'value'->>'id'=$1 FOR UPDATE`,
      [inventoryId],
    )).rows[0];
    if (!row || row.data?.value?.archived) throw fail(409, 'A product is no longer available.');
    const value = structuredClone(row.data.value);
    const batches = Array.isArray(value.batches) ? value.batches : [];
    if (batches.length) {
      const eligible = batches
        .filter(batch => Number(batch.quantity) > 0 && new Date(batch.expiresOn) >= now)
        .sort((left, right) => new Date(left.expiresOn) - new Date(right.expiresOn));
      const available = eligible.reduce((sum, batch) => sum + Number(batch.quantity), 0);
      if (available < quantity) throw fail(409, `${value.name || 'A product'} does not have enough unexpired stock.`);
      let remaining = quantity;
      for (const batch of eligible) {
        if (!remaining) break;
        const used = Math.min(remaining, Number(batch.quantity));
        batch.quantity = Number(batch.quantity) - used;
        remaining -= used;
      }
    } else {
      const expired = value.expiresOn && new Date(value.expiresOn) < now;
      if (expired || Number(value.quantity) < quantity) {
        throw fail(409, `${value.name || 'A product'} does not have enough available stock.`);
      }
    }
    const previous = Number(value.quantity) || 0;
    value.quantity = previous - quantity;
    value.movements = [...(Array.isArray(value.movements) ? value.movements : []), {
      id: `MOV-${crypto.randomUUID()}`,
      type: 'Stock Out',
      quantity,
      previousBalance: previous,
      newBalance: value.quantity,
      reason: `Reserved for ${orderId}`,
      staff: 'Online checkout',
      at: now.toISOString(),
      reference: orderId,
      batchNumber: '',
    }];
    value.lastAudit = `Stock Out -${quantity} (online order ${orderId})`;
    const data = { ...row.data, value };
    await client.query(
      'UPDATE inventory SET data=$2,version=version+1,updated_at=NOW() WHERE id=$1',
      [row.id, data],
    );
    const unitPrice = Math.max(0, Number(value.sellingPrice) || 0);
    total += unitPrice * quantity;
    verifiedItems.push({ inventoryId, name: String(value.name || inventoryId), unitPrice, quantity });
  }
  order.items = verifiedItems;
  order.total = total;
  order.status = 'Reserved';
  order.fulfillment = 'Clinic pickup';
  order.paymentMethod = requestedPaymentMethod;
  order.paymentTiming = requestedPaymentTiming;
}
function createProductOrderPayment(order, actor) {
  if (!['MMQR', 'Cash'].includes(order.paymentMethod)) return null;
  const paymentId = `PAY-${order.id}`;
  const payment = {
    id: paymentId,
    orderId: order.id,
    owner: String(order.ownerName || 'Registered owner'),
    pet: 'Product order',
    amount: Number(order.total),
    status: 'Unpaid',
    paymentTiming: order.paymentTiming,
  };
  return order.paymentMethod === 'MMQR'
    ? createMmqrPayment(payment, actor)
    : createCashPayment(payment, actor);
}
const activeBooking = (table, value) => {
  const status = normalizedBookingText(value?.status);
  if (table === 'appointments') return status !== 'cancelled';
  return !['completed', 'cancelled', 'missed'].includes(status);
};
const petCareStatusForAppointment = status => {
  const value = normalizedBookingText(status);
  if (['checked in', 'waiting', 'called', 'arrived'].includes(value)) return 'checkedIn';
  if (['in consultation', 'in progress'].includes(value)) return 'inProgress';
  if (value === 'completed') return 'completed';
  if (['cancelled', 'missed'].includes(value)) return 'cancelled';
  return 'confirmed';
};
const syncLinkedPetCareAppointment = async (client, appointment) => {
  const appointmentId = String(appointment?.id || '');
  if (!appointmentId) return;
  await client.query(
    `UPDATE pet_care_bookings
     SET data=jsonb_set(
       jsonb_set(
         jsonb_set(
           jsonb_set(data,'{value,status}',to_jsonb($2::text),true),
           '{value,date}',to_jsonb($3::text),true),
         '{value,time}',to_jsonb($4::text),true),
       '{value,provider}',to_jsonb($5::text),true),
         version=version+1,updated_at=NOW()
     WHERE data->'value'->>'linkedAppointmentId'=$1`,
    [
      appointmentId,
      petCareStatusForAppointment(appointment.status),
      String(appointment.date || ''),
      String(appointment.time || ''),
      String(appointment.veterinarian || ''),
    ],
  );
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
  return ['pet care','grooming','bathing','boarding','day care','overnight stay','nail clipping','nail trimming','ear cleaning','anal gland cleaning']
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
  app.get('/receipts/verify/:token', wrap(async (req, res) => {
    const row = (await pool.query(
      'SELECT * FROM payment_receipts WHERE public_token=$1',
      [String(req.params.token || '')],
    )).rows[0];
    if (!row) throw fail(404, 'Receipt not found.');
    await pool.query(
      "INSERT INTO receipt_delivery_events(receipt_number,event,metadata) VALUES($1,'receipt.viewed',$2)",
      [row.receipt_number, { ipHash: hash(String(req.ip || 'unknown')) }],
    );
    const receipt = publicReceipt(row);
    if (!String(req.headers.accept || '').includes('text/html')) return res.json(receipt);
    res.type('html').send(`<!doctype html><html><head><meta name="viewport" content="width=device-width"><title>Receipt ${receipt.receiptNumber}</title><style>body{font:16px system-ui;background:#f3faf7;color:#16352a;padding:32px}.card{max-width:520px;margin:auto;background:white;padding:28px;border-radius:20px;box-shadow:0 8px 30px #0001}.ok{color:#08794d;font-weight:800;font-size:22px}dt{color:#66756f;margin-top:16px}dd{margin:4px 0;font-weight:700}</style></head><body><main class="card"><div class="ok">✓ Valid clinic receipt</div><dl><dt>Receipt</dt><dd>${receipt.receiptNumber}</dd><dt>Paid amount</dt><dd>${receipt.paidAmount} ${receipt.currency}</dd><dt>Payment method</dt><dd>${receipt.paymentMethod}</dd><dt>Paid at</dt><dd>${receipt.paidAt}</dd><dt>Invoice status</dt><dd>${receipt.invoiceStatus}</dd></dl></main></body></html>`);
  }));
  app.get('/receipts/:token/pdf', wrap(async (req, res) => {
    const row = (await pool.query(
      'SELECT * FROM payment_receipts WHERE public_token=$1',
      [String(req.params.token || '')],
    )).rows[0];
    if (!row) throw fail(404, 'Receipt not found.');
    const pdf = await receiptPdfBuffer(row.data);
    await pool.query(
      "INSERT INTO receipt_delivery_events(receipt_number,event,metadata) VALUES($1,'receipt.downloaded',$2)",
      [row.receipt_number, { ipHash: hash(String(req.ip || 'unknown')) }],
    );
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="${row.receipt_number}.pdf"`);
    res.send(pdf);
  }));
  app.use(['/data', '/reports', '/queue', '/payments', '/auth/logout', '/auth/change-password', '/devices'], async (req, res, next) => {
    try {
      const token = (req.headers.authorization || '').replace(/^Bearer /, '');
      const session = (await pool.query('SELECT s.* FROM app_sessions s JOIN app_accounts a ON a.id=s.account_id AND a.active AND a.role=s.role WHERE s.token_hash=$1 AND s.expires_at>NOW()', [hash(token)])).rows[0];
      if (!session) return res.status(401).json({ message: 'Please sign in again.' });
      req.session = session;
      next();
    } catch (_) { res.status(503).json({ message: 'Database unavailable.' }); }
  });
  const requirePaymentStaff = req => {
    if (!['staff', 'systemAdmin'].includes(req.session.role)) throw fail(403, 'Staff payment access required.');
  };
  const mutatePayment = async (req, mutation, { allowOwner = false } = {}) => {
    const ownerAccess = allowOwner && req.session.role === 'petOwner';
    if (!ownerAccess) requirePaymentStaff(req);
    const invoiceId = String(req.params.invoiceId || '').trim();
    if (!invoiceId || invoiceId.length > 200) throw fail(400, 'A valid invoice ID is required.');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const rows = (await client.query(
        `SELECT * FROM payments WHERE data->'value'->>'id'=$1${ownerAccess ? ' AND owner_id=$2' : ''} ORDER BY created_at FOR UPDATE`,
        ownerAccess ? [invoiceId, req.session.account_id] : [invoiceId],
      )).rows;
      if (rows.length !== 1) throw fail(rows.length ? 409 : 404, 'Payment record not found or is not unique.');
      const row = rows[0];
      const previousValue = row.data.value;
      let nextValue = await mutation(previousValue, client);
      if (nextValue.status === 'Paid' && !nextValue.receipt) {
        const receiptRow = await createPaymentReceipt(client, row, nextValue, paymentActor(req.session));
        nextValue.receipt = {
          receiptNumber: receiptRow.receipt_number,
          verificationUrl: receiptRow.data.verificationUrl,
          pdfUrl: `${String(process.env.PUBLIC_BASE_URL || 'http://127.0.0.1:5050').replace(/\/$/, '')}/receipts/${receiptRow.public_token}/pdf`,
          generatedAt: receiptRow.created_at,
        };
        nextValue.auditTrail = [...(nextValue.auditTrail || []), paymentAuditEvent(
          paymentActor(req.session), 'receipt.generated', 'Paid', 'Paid', { receiptNumber: receiptRow.receipt_number }, new Date(),
        )];
      }
      await appendPaymentEvents(client, row, previousValue, nextValue);
      await appendMmqrAttempts(client, row, previousValue, nextValue);
      const data = { ...row.data, value: nextValue };
      const record = (await client.query(
        'UPDATE payments SET data=$2,version=version+1,updated_at=NOW() WHERE id=$1 RETURNING id,owner_id,data,version',
        [row.id, data],
      )).rows[0];
      let productOrderChanged = false;
      if (nextValue.orderId) {
        const orderRow = (await client.query(
          `SELECT * FROM product_orders
           WHERE owner_id=$1 AND data->'value'->>'id'=$2
           ORDER BY created_at FOR UPDATE`,
          [row.owner_id, nextValue.orderId],
        )).rows[0];
        if (orderRow) {
          const orderData = structuredClone(orderRow.data);
          orderData.value.paymentStatus = nextValue.status;
          orderData.value.mmqr = nextValue.mmqr || orderData.value.mmqr;
          if (nextValue.receipt) orderData.value.receipt = nextValue.receipt;
          orderData.value.paymentAuditTrail = (nextValue.auditTrail || []).map(event => ({
            id: event.id,
            at: event.at,
            action: event.action,
            fromStatus: event.fromStatus,
            toStatus: event.toStatus,
          }));
          await client.query(
            'UPDATE product_orders SET data=$2,version=version+1,updated_at=NOW() WHERE id=$1',
            [orderRow.id, orderData],
          );
          productOrderChanged = true;
        }
      }
      await client.query('COMMIT');
      broadcastChange('payments');
      if (productOrderChanged) broadcastChange('product_orders', { ownerId: row.owner_id });
      return record;
    } catch (error) {
      await client.query('ROLLBACK');
      if (error.code === '23505') throw fail(409, 'That MMQR, settlement, or receipt reference has already been used.');
      throw error;
    } finally {
      client.release();
    }
  };
  app.post('/webhooks/mmqr', wrap(async (req, res) => {
    const input = {
      merchantId: String(req.body.merchantId || ''),
      invoiceId: String(req.body.invoiceId || ''),
      reference: String(req.body.reference || ''),
      amount: Number(req.body.amount),
      providerTransactionId: String(req.body.providerTransactionId || ''),
      status: String(req.body.status || '').toLowerCase(),
    };
    if (input.status !== 'confirmed') throw fail(400, 'Only confirmed MMQR settlements are accepted.');
    verifyMmqrWebhook(
      input,
      req.headers['x-mmqr-signature'],
      process.env.MMQR_SETTLEMENT_SECRET,
    );
    const alreadyProcessed = (await pool.query(
      `SELECT id,owner_id,data,version FROM payments
       WHERE data->'value'->'settlement'->>'providerTransactionId'=$1 LIMIT 1`,
      [input.providerTransactionId],
    )).rows[0];
    if (alreadyProcessed) return res.json({ record: alreadyProcessed, queued: false, idempotent: true });
    const providerRequest = {
      ...req,
      params: { invoiceId: input.invoiceId },
      session: { account_id: 'provider:mmqr', role: 'systemAdmin' },
    };
    let queued = false;
    const record = await mutatePayment(providerRequest, async (value, client) => {
      const expired = value.mmqr?.status === 'Expired' ||
        new Date(value.mmqr?.expiresAt || 0).getTime() <= Date.now();
      if (expired) {
        await client.query(
          `INSERT INTO payment_reconciliation_queue(payment_id,provider_transaction_id,payload)
           VALUES($1,$2,$3) ON CONFLICT(provider_transaction_id) DO NOTHING`,
          [value.id, input.providerTransactionId, input],
        );
        queued = true;
        const next = paymentCopy(value);
        next.auditTrail = [...(next.auditTrail || []), paymentAuditEvent(
          paymentActor(providerRequest.session),
          'mmqr.late_settlement_queued',
          value.status,
          value.status,
          { reference: input.reference, providerTransactionId: input.providerTransactionId },
          new Date(),
        )];
        return next;
      }
      return settleMmqrPayment(value, input, paymentActor(providerRequest.session));
    });
    res.status(queued ? 202 : 200).json({ record, queued });
  }));
  app.post('/payments/:invoiceId/mmqr', wrap(async (req, res) => {
    const record = await mutatePayment(req, async value => prepareMmqrPayment(
      createMmqrPayment(value, paymentActor(req.session)),
    ));
    res.status(201).json({ record });
  }));
  app.post('/payments/:invoiceId/mmqr/settle', wrap(async (req, res) => {
    requirePaymentStaff(req);
    const input = {
      reference: req.body.reference,
      amount: req.body.amount,
      providerTransactionId: req.body.providerTransactionId,
    };
    verifyMmqrProof(input, req.body.settlementProof || req.headers['x-mmqr-settlement-proof'], process.env.MMQR_SETTLEMENT_SECRET);
    const record = await mutatePayment(req, async (value, client) => {
      const transactionId = String(input.providerTransactionId || '').trim();
      const duplicate = (await client.query(
        `SELECT 1 FROM payments
         WHERE data->'value'->'settlement'->>'providerTransactionId'=$1
           AND data->'value'->>'id'<>$2 LIMIT 1`,
        [transactionId, req.params.invoiceId],
      )).rows[0];
      if (duplicate) throw fail(409, 'This provider transaction has already settled another invoice.');
      return settleMmqrPayment(value, input, paymentActor(req.session));
    });
    res.json({ record });
  }));
  app.post('/payments/:invoiceId/mmqr/reconcile', wrap(async (req, res) => {
    const input = {
      reference: req.body.reference,
      amount: req.body.amount,
      receiptReference: req.body.receiptReference,
      note: req.body.note,
    };
    const record = await mutatePayment(req, async (value, client) => {
      const receiptReference = String(input.receiptReference || '').trim();
      const duplicate = receiptReference && (await client.query(
        `SELECT 1 FROM payments
         WHERE data->'value'->'settlement'->>'receiptReference'=$1
           AND data->'value'->>'id'<>$2 LIMIT 1`,
        [receiptReference, req.params.invoiceId],
      )).rows[0];
      if (duplicate) throw fail(409, 'This receipt reference has already settled another invoice.');
      return reconcileMmqrPayment(value, input, paymentActor(req.session));
    });
    res.json({ record });
  }));
  app.post('/payments/:invoiceId/mmqr/cancel', wrap(async (req, res) => {
    const record = await mutatePayment(
      req,
      value => cancelMmqrPayment(value, req.body, paymentActor(req.session)),
      { allowOwner: true },
    );
    res.json({ record });
  }));
  app.post('/payments/:invoiceId/mmqr/expire', wrap(async (req, res) => {
    const record = await mutatePayment(
      req,
      value => expireMmqrPayment(value, paymentActor(req.session)),
      { allowOwner: true },
    );
    res.json({ record });
  }));
  app.post('/payments/:invoiceId/mmqr/displayed', wrap(async (req, res) => {
    const record = await mutatePayment(
      req,
      value => markMmqrDisplayed(value, paymentActor(req.session)),
      { allowOwner: true },
    );
    res.json({ record });
  }));
  app.post('/payments/:invoiceId/mmqr/regenerate', wrap(async (req, res) => {
    const record = await mutatePayment(req, async value => {
      const now = new Date();
      const expired = value.status === 'Pending'
        ? expireMmqrPayment(value, paymentActor(req.session), { now })
        : value;
      return prepareMmqrPayment(createMmqrPayment(expired, paymentActor(req.session), { now }));
    }, { allowOwner: true });
    res.status(201).json({ record });
  }));
  app.get('/payments/:invoiceId/status', wrap(async (req, res) => {
    const clinicAccess = ['staff', 'systemAdmin'].includes(req.session.role);
    const params = clinicAccess
      ? [String(req.params.invoiceId || '')]
      : [String(req.params.invoiceId || ''), req.session.account_id];
    const row = (await pool.query(
      `SELECT id,owner_id,data,version FROM payments
       WHERE data->'value'->>'id'=$1${clinicAccess ? '' : ' AND owner_id=$2'} LIMIT 1`,
      params,
    )).rows[0];
    if (!row) throw fail(404, 'Payment not found.');
    res.json({ record: row });
  }));
  app.post('/payments/:invoiceId/receipt/email', wrap(async (req, res) => {
    const clinicAccess = ['staff', 'systemAdmin'].includes(req.session.role);
    const params = clinicAccess
      ? [String(req.params.invoiceId || '')]
      : [String(req.params.invoiceId || ''), req.session.account_id];
    const payment = (await pool.query(
      `SELECT * FROM payments WHERE data->'value'->>'id'=$1${clinicAccess ? '' : ' AND owner_id=$2'} LIMIT 1`,
      params,
    )).rows[0];
    if (!payment?.data?.value?.receipt?.receiptNumber) throw fail(409, 'A generated receipt is required before email delivery.');
    const account = (await pool.query(
      'SELECT email,full_name FROM app_accounts WHERE id=$1',
      [payment.owner_id],
    )).rows[0];
    if (!account?.email) throw fail(409, 'The customer account has no receipt email address.');
    await pool.query(
      `INSERT INTO receipt_delivery_jobs(receipt_number,email,recipient_name)
       VALUES($1,$2,$3)
       ON CONFLICT(receipt_number,email) DO UPDATE SET
         status=CASE WHEN receipt_delivery_jobs.status='sent' THEN 'sent' ELSE 'pending' END,
         next_attempt_at=NOW(),last_error=NULL`,
      [payment.data.value.receipt.receiptNumber, account.email, account.full_name || ''],
    );
    res.status(202).json({ queued: true, email: account.email.replace(/(^.).*(@.*$)/, '$1***$2') });
  }));
  app.post('/payments/:invoiceId/cash/collect', wrap(async (req, res) => {
    const record = await mutatePayment(req, async (value, client) => {
      const receiptReference = String(req.body.receiptReference || '').trim();
      const duplicate = receiptReference && (await client.query(
        `SELECT 1 FROM payments
         WHERE data->'value'->'settlement'->>'receiptReference'=$1
           AND data->'value'->>'id'<>$2 LIMIT 1`,
        [receiptReference, req.params.invoiceId],
      )).rows[0];
      if (duplicate) throw fail(409, 'This receipt reference has already settled another invoice.');
      return collectCashPayment(value, req.body, paymentActor(req.session));
    });
    res.json({ record });
  }));
  app.get('/payments/:invoiceId/audit', wrap(async (req, res) => {
    requirePaymentStaff(req);
    const rows = (await pool.query(
      `SELECT data->'value'->'auditTrail' AS audit_trail
       FROM payments WHERE data->'value'->>'id'=$1 ORDER BY created_at`,
      [String(req.params.invoiceId || '')],
    )).rows;
    if (rows.length !== 1) throw fail(rows.length ? 409 : 404, 'Payment record not found or is not unique.');
    res.json({ events: rows[0].audit_trail || [] });
  }));

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
      await syncLinkedPetCareAppointment(client, appointmentData.value);
      const notification = await saveOwnerNotification(
        client,
        appointmentRow.owner_id,
        'Queue check-in',
        `${petName} is checked in as ${queueNumber}.`,
      );
      await client.query('COMMIT');
      broadcastChange('appointments', { ownerId: appointmentRow.owner_id });
      broadcastChange('pet_care_bookings', { ownerId: appointmentRow.owner_id });
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
        const requiresMedicalRecord = value.serviceGroup !== 'petCareService';
        value.medicalRecordId = req.body.medicalRecordId || value.medicalRecordId || null;
        if (requiresMedicalRecord) {
          if (!value.medicalRecordId) throw fail(400, 'Complete the medical record before completing the queue ticket.');
          const medicalRecord = (await client.query(
            `SELECT 1 FROM medical_records
             WHERE data->'value'->>'id'=$1
               AND data->'value'->>'appointmentId'=$2
               AND data->'value'->>'finalized'='true'
             LIMIT 1`,
            [value.medicalRecordId, appointmentId],
          )).rows[0];
          if (!medicalRecord) throw fail(409, 'The finalized medical record must be saved before completing the queue ticket.');
        }
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
        await syncLinkedPetCareAppointment(client, appointmentData.value);
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
      broadcastChange('pet_care_bookings', { ownerId: ticket.owner_id });
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
          END,
          'schedule',CASE WHEN a.role='doctor'
            THEN COALESCE(dp.data->'value'->'schedule','{}'::jsonb)
            ELSE '{}'::jsonb END,
          'leaveDates',CASE WHEN a.role='doctor'
            THEN COALESCE(dp.data->'value'->'leaveDates','[]'::jsonb)
            ELSE '[]'::jsonb END)) AS data
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
      let inventoryChanged = false;
      let paymentChanged = false;
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
        if (req.params.table === 'product_orders' && !existing) {
          await reserveProductOrderInventory(client, item.data.value, item.data.value.id || item.id);
          inventoryChanged = true;
        }
        let ownerId = existing?.owner_id || req.session.account_id;
        if (!existing && p.scope === 'owner' && req.session.role !== 'petOwner' && item.ownerId) {
          const target = await client.query("SELECT id FROM app_accounts WHERE id=$1 AND role='petOwner'", [item.ownerId]);
          if (!target.rowCount) throw fail(400, 'Owner account not found.');
          ownerId = item.ownerId;
        }
        if (req.params.table === 'product_orders' && !existing && ['MMQR', 'Cash'].includes(item.data.value.paymentMethod)) {
          const order = item.data.value;
          const rawPayment = createProductOrderPayment(order, paymentActor(req.session));
          const payment = rawPayment.paymentMethod === 'MMQR'
            ? await prepareMmqrPayment(rawPayment)
            : rawPayment;
          const paymentId = payment.id;
          await client.query(
            'INSERT INTO payments(id,owner_id,data) VALUES($1,$2,$3)',
            [`${ownerId}:${paymentId}`, ownerId, { key: paymentId, value: payment }],
          );
          for (const event of payment.auditTrail || []) {
            await client.query(
              `INSERT INTO payment_audit_events(id,payment_id,owner_id,event)
               VALUES($1,$2,$3,$4) ON CONFLICT(id) DO NOTHING`,
              [event.id, paymentId, ownerId, event],
            );
          }
          if (payment.mmqr?.attemptId) {
            await client.query(
              `INSERT INTO mmqr_payment_attempts(attempt_id,payment_id,owner_id,reference,payload_hash,data)
               VALUES($1,$2,$3,$4,$5,$6)`,
              [payment.mmqr.attemptId, paymentId, ownerId, payment.mmqr.reference, payment.mmqr.payloadHash || null, payment.mmqr],
            );
          }
          order.paymentId = paymentId;
          order.paymentStatus = payment.status;
          if (payment.mmqr) order.mmqr = payment.mmqr;
          paymentChanged = true;
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
        if (req.params.table === 'pet_care_bookings') {
          const value = item.data.value || {};
          const previous = existing?.data?.value || {};
          const date = bookingDate(value);
          const time = bookingTime(value);
          const providerId = normalizedBookingText(value.providerId);
          const providerName = normalizedBookingText(value.provider);
          const providerChanged = existing && (
            normalizedBookingText(previous.providerId) !== providerId ||
            normalizedBookingText(previous.provider) !== providerName
          );
          const shouldCheckProvider = activeBooking(req.params.table, value) &&
            date && time && (providerId || providerName) && (
              !existing || !activeBooking(req.params.table, previous) ||
              bookingDate(previous) !== date || bookingTime(previous) !== time ||
              providerChanged
            );
          if (shouldCheckProvider) {
            const providerKey = providerId || providerName;
            await client.query(
              'SELECT pg_advisory_xact_lock(hashtext($1))',
              [`pet-care-provider:${providerKey}:${date}:${time}`],
            );
            const candidates = (await client.query(
              `SELECT data FROM pet_care_bookings
               WHERE id<>$1 AND LEFT(data->'value'->>'date',10)=$2
                 AND data->'value'->>'time'=$3`,
              [item.id, date, time],
            )).rows;
            const providerBooked = candidates.some(row => {
              const candidate = row.data?.value || {};
              const sameProvider = providerId
                ? normalizedBookingText(candidate.providerId) === providerId
                : normalizedBookingText(candidate.provider) === providerName;
              return sameProvider && activeBooking(req.params.table, candidate);
            });
            if (providerBooked) {
              throw fail(409, 'That pet-care provider is already booked at this date and time.');
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
          const schedulingRulesChanged = existing && (
            normalizedBookingText(existing.data.value.veterinarianId) !== normalizedBookingText(value.veterinarianId) ||
            normalizedBookingText(existing.data.value.veterinarian) !== normalizedBookingText(value.veterinarian) ||
            bookingDuration(existing.data.value) !== bookingDuration(value)
          );
          const becameActive = existing && previousStatus === 'Cancelled' && isActiveBooking;
          if (isActiveBooking && slotKey.date && slotKey.time &&
              (!existing || slotChanged || schedulingRulesChanged || becameActive)) {
            const durationMinutes = bookingDuration(value);
            const clinicScheduleError = appointmentScheduleError({
              profile: null,
              date: slotKey.date,
              time: slotKey.time,
              durationMinutes,
            });
            if (clinicScheduleError) throw fail(409, clinicScheduleError);
            const doctorId = String(value.veterinarianId || '');
            const doctorName = String(value.veterinarian || '');
            const doctorKey = normalizedBookingText(doctorId || doctorName);
            if (doctorKey) {
              await client.query(
                'SELECT pg_advisory_xact_lock(hashtext($1))',
                [`appointment-doctor-day:${doctorKey}:${slotKey.date}`],
              );
            }
            const profile = (await client.query(
              `SELECT dp.data->'value' AS value
               FROM doctor_profiles dp
               LEFT JOIN app_accounts a ON a.id=dp.owner_id
               WHERE ($1<>'' AND dp.owner_id=$1)
                  OR ($2<>'' AND LOWER(COALESCE(dp.data->'value'->>'name',a.full_name,a.username))=LOWER($2))
               LIMIT 1`,
              [doctorId, doctorName],
            )).rows[0]?.value;
            const doctorScheduleError = appointmentScheduleError({
              profile,
              date: slotKey.date,
              time: slotKey.time,
              durationMinutes,
            });
            if (doctorScheduleError) throw fail(409, doctorScheduleError);
            const sameDayAppointments = (await client.query(
              `SELECT data FROM appointments
               WHERE id<>$1 AND LEFT(data->'value'->>'date',10)=$2
                 AND COALESCE(data->'value'->>'status','')<>'Cancelled'`,
              [item.id, slotKey.date],
            )).rows;
            if (sameDayAppointments.some(row => {
              const candidate = row.data?.value || {};
              return sameAppointmentDoctor(candidate, value) &&
                bookingIntervalsOverlap(candidate, value);
            })) {
              throw fail(409, 'That veterinarian already has an overlapping appointment.');
            }
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
        if (inventoryChanged) broadcastChange('inventory');
        if (paymentChanged) broadcastChange('payments');
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
module.exports = {
  installApi,
  syncUserDirectoryAccount,
  findAccountByIdentifier,
  bookingTimeMinutes,
  bookingIntervalsOverlap,
  sameAppointmentDoctor,
  appointmentScheduleError,
  reserveProductOrderInventory,
  createProductOrderPayment,
  createMmqrPayment,
  settleMmqrPayment,
  reconcileMmqrPayment,
  cancelMmqrPayment,
  createCashPayment,
  collectCashPayment,
  verifyMmqrProof,
  mmqrProofPayload,
  renderMmqrQr,
  prepareMmqrPayment,
  expireMmqrPayment,
  markMmqrDisplayed,
  expirePendingMmqrPayments,
  receiptPdfBuffer,
  verifyMmqrWebhook,
  mmqrWebhookProofPayload,
  processReceiptDeliveryJobs,
};

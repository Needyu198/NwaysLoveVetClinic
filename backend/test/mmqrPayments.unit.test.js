const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {
  createMmqrPayment,
  settleMmqrPayment,
  reconcileMmqrPayment,
  cancelMmqrPayment,
  verifyMmqrProof,
  mmqrProofPayload,
  renderMmqrQr,
  expireMmqrPayment,
  receiptPdfBuffer,
  verifyMmqrWebhook,
  mmqrWebhookProofPayload,
  markMmqrDisplayed,
  prepareMmqrPayment,
} = require('../src/api');

const actor = { actorId: 'staff-1', actorRole: 'staff' };
const invoice = () => ({
  id: 'INV-100',
  owner: 'Owner',
  pet: 'Pet',
  amount: 45000,
  status: 'Unpaid',
});
const createdAt = new Date('2026-11-10T02:00:00.000Z');

test('MMQR creation binds a unique reference to the exact invoice amount and audits it', () => {
  const payment = createMmqrPayment(invoice(), actor, {
    now: createdAt,
    reference: 'MMQR-TEST-100',
  });
  assert.equal(payment.status, 'Pending');
  assert.deepEqual(
    { reference: payment.mmqr.reference, amount: payment.mmqr.amount, currency: payment.mmqr.currency },
    { reference: 'MMQR-TEST-100', amount: 45000, currency: 'MMK' },
  );
  assert.match(payment.mmqr.qrPayload, /invoice=INV-100/);
  assert.equal(payment.auditTrail[0].action, 'mmqr.created');
  assert.equal(invoice().status, 'Unpaid');
});

test('MMQR cannot guess an outstanding amount for a partially paid invoice', () => {
  assert.throws(
    () => createMmqrPayment({ ...invoice(), status: 'Partially Paid' }, actor),
    error => error.status === 409 && /fully unpaid/.test(error.message),
  );
});

test('provider settlement requires matching amount/reference and cannot finalize twice', () => {
  const pending = createMmqrPayment(invoice(), actor, { now: createdAt, reference: 'MMQR-TEST-100' });
  assert.throws(
    () => settleMmqrPayment(pending, { reference: 'WRONG', amount: 45000, providerTransactionId: 'TX-1' }, actor),
    error => error.status === 409 && /reference/.test(error.message),
  );
  assert.throws(
    () => settleMmqrPayment(pending, { reference: 'MMQR-TEST-100', amount: 1, providerTransactionId: 'TX-1' }, actor),
    error => error.status === 409 && /amount/.test(error.message),
  );
  const paid = settleMmqrPayment(
    pending,
    { reference: 'MMQR-TEST-100', amount: 45000, providerTransactionId: 'TX-1' },
    actor,
    { now: new Date('2026-11-10T02:05:00.000Z') },
  );
  assert.equal(paid.status, 'Paid');
  assert.equal(paid.settlement.type, 'provider_verified');
  assert.ok(paid.auditTrail.some(event => event.action === 'mmqr.provider_settled'));
  assert.equal(paid.auditTrail.at(-1).action, 'payment.settled');
  assert.throws(
    () => settleMmqrPayment(paid, { reference: 'MMQR-TEST-100', amount: 45000, providerTransactionId: 'TX-1' }, actor),
    error => error.status === 409 && /already settled/.test(error.message),
  );
});

test('staff reconciliation requires evidence and is visibly distinct in audit history', () => {
  const pending = createMmqrPayment(invoice(), actor, { reference: 'MMQR-TEST-100' });
  assert.throws(
    () => reconcileMmqrPayment(pending, { reference: 'MMQR-TEST-100', amount: 45000, receiptReference: '', note: 'checked carefully' }, actor),
    error => error.status === 400 && /receipt/.test(error.message),
  );
  const paid = reconcileMmqrPayment(pending, {
    reference: 'MMQR-TEST-100',
    amount: 45000,
    receiptReference: 'RECEIPT-99',
    note: 'Checked against the daily acquiring statement.',
  }, actor);
  assert.equal(paid.settlement.type, 'staff_reconciliation');
  const reconciliation = paid.auditTrail.find(event => event.action === 'mmqr.staff_reconciled');
  assert.equal(reconciliation.details.receiptReference, 'RECEIPT-99');
  assert.equal(paid.auditTrail.at(-1).action, 'payment.settled');
});

test('cancelling leaves the invoice unpaid and preserves the lifecycle history', () => {
  const pending = createMmqrPayment(invoice(), actor, { reference: 'MMQR-TEST-100' });
  const cancelled = cancelMmqrPayment(pending, { reason: 'Customer requested another payment method' }, actor);
  assert.equal(cancelled.status, 'Unpaid');
  assert.equal(cancelled.mmqr.status, 'Cancelled');
  assert.deepEqual(cancelled.auditTrail.map(event => event.action), ['mmqr.created', 'mmqr.cancelled']);
});

test('provider proof is HMAC-verifiable and fails closed when missing or altered', () => {
  const input = { reference: 'MMQR-TEST-100', amount: 45000, providerTransactionId: 'TX-1' };
  const secret = 'test-settlement-secret';
  const proof = crypto.createHmac('sha256', secret).update(mmqrProofPayload(input)).digest('hex');
  assert.doesNotThrow(() => verifyMmqrProof(input, proof, secret));
  const altered = `${proof[0] === '0' ? '1' : '0'}${proof.slice(1)}`;
  assert.throws(() => verifyMmqrProof(input, altered, secret), error => error.status === 403);
  assert.throws(() => verifyMmqrProof(input, proof, ''), error => error.status === 503);
});

test('amount-bound MMQR payload renders as a QR image with a saved hash', async () => {
  const pending = createMmqrPayment(invoice(), actor, { reference: 'MMQR-QR-1' });
  const rendered = await renderMmqrQr(pending);
  assert.match(rendered.mmqr.qrImageDataUrl, /^data:image\/png;base64,/);
  assert.match(rendered.mmqr.payloadHash, /^[a-f0-9]{64}$/);
  assert.equal(rendered.mmqr.amount, 45000);
  assert.ok(rendered.mmqr.attemptId.startsWith('MMA-'));
});

test('configured acquirer supplies the wallet-compatible QR payload', async () => {
  const previous = {
    endpoint: process.env.MMQR_PROVIDER_QR_ENDPOINT,
    key: process.env.MMQR_PROVIDER_API_KEY,
    merchant: process.env.MMQR_MERCHANT_ID,
  };
  process.env.MMQR_PROVIDER_QR_ENDPOINT = 'https://acquirer.example/qr';
  process.env.MMQR_PROVIDER_API_KEY = 'secret';
  process.env.MMQR_MERCHANT_ID = 'MERCHANT-1';
  const pending = createMmqrPayment(invoice(), actor, { reference: 'MMQR-ACQ-1', attemptId: 'MMA-ACQ-1' });
  let sent;
  const prepared = await prepareMmqrPayment(pending, async (url, options) => {
    sent = { url, options };
    return { ok: true, async json() { return { qrPayload: '000201-provider-emv-payload', reference: 'MMQR-ACQ-1', providerAttemptId: 'P-1' }; } };
  });
  assert.equal(sent.options.headers['Idempotency-Key'], 'MMA-ACQ-1');
  assert.equal(prepared.mmqr.providerMode, 'acquirer_api');
  assert.equal(prepared.mmqr.qrPayload, '000201-provider-emv-payload');
  assert.match(prepared.mmqr.qrImageDataUrl, /^data:image\/png;base64,/);
  for (const [key, value] of Object.entries(previous)) {
    const envKey = key === 'endpoint' ? 'MMQR_PROVIDER_QR_ENDPOINT' : key === 'key' ? 'MMQR_PROVIDER_API_KEY' : 'MMQR_MERCHANT_ID';
    if (value == null) delete process.env[envKey]; else process.env[envKey] = value;
  }
});

test('displaying one QR attempt records one immutable display event', () => {
  const pending = createMmqrPayment(invoice(), actor, { attemptId: 'MMA-DISPLAY' });
  const displayed = markMmqrDisplayed(pending, actor);
  const displayedAgain = markMmqrDisplayed(displayed, actor);
  assert.equal(displayedAgain.auditTrail.filter(event => event.action === 'mmqr.displayed').length, 1);
});

test('expired QR attempts return invoice to unpaid and remain in history on regeneration', () => {
  const pending = createMmqrPayment(invoice(), actor, {
    now: new Date('2026-11-10T02:00:00.000Z'),
    reference: 'MMQR-OLD',
    attemptId: 'MMA-OLD',
  });
  const expired = expireMmqrPayment(pending, actor, {
    now: new Date('2026-11-10T02:16:00.000Z'),
  });
  const regenerated = createMmqrPayment(expired, actor, {
    now: new Date('2026-11-10T02:16:00.000Z'),
    reference: 'MMQR-NEW',
    attemptId: 'MMA-NEW',
  });
  assert.equal(expired.status, 'Unpaid');
  assert.equal(expired.mmqr.status, 'Expired');
  assert.equal(regenerated.mmqr.reference, 'MMQR-NEW');
  assert.equal(regenerated.mmqrAttempts.at(-1).reference, 'MMQR-OLD');
});

test('digital receipt PDF contains a valid PDF document', async () => {
  const pdf = await receiptPdfBuffer({
    receiptNumber: 'RCP-2026-001001',
    orderId: 'ORD-1',
    customerName: 'Owner',
    paymentMethod: 'MMQR',
    mmqrReference: 'MMQR-1',
    paidAt: '2026-11-10T02:05:00.000Z',
    items: [{ name: 'Pet Food', quantity: 2, unitPrice: 5000 }],
    total: 10000,
    currency: 'MMK',
    verificationUrl: 'https://clinic.example/receipts/verify/token',
    clinic: { name: "Nway's Love Vet Clinic", address: '', phone: '' },
  });
  assert.equal(pdf.subarray(0, 5).toString(), '%PDF-');
  assert.ok(pdf.length > 1000);
});

test('provider webhook signature binds merchant, invoice, amount and transaction', () => {
  const previousMerchant = process.env.MMQR_MERCHANT_ID;
  process.env.MMQR_MERCHANT_ID = 'MERCHANT-1';
  const input = {
    merchantId: 'MERCHANT-1',
    invoiceId: 'INV-100',
    reference: 'MMQR-100',
    amount: 45000,
    providerTransactionId: 'TX-100',
    status: 'confirmed',
  };
  const secret = 'webhook-secret';
  const signature = crypto.createHmac('sha256', secret).update(mmqrWebhookProofPayload(input)).digest('hex');
  assert.doesNotThrow(() => verifyMmqrWebhook(input, signature, secret));
  assert.throws(
    () => verifyMmqrWebhook({ ...input, amount: 45001 }, signature, secret),
    error => error.status === 403,
  );
  if (previousMerchant == null) delete process.env.MMQR_MERCHANT_ID;
  else process.env.MMQR_MERCHANT_ID = previousMerchant;
});

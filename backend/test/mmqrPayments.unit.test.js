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
  expireMmqrPayment,
  receiptPdfBuffer,
  verifyMmqrWebhook,
  mmqrWebhookProofPayload,
  markMmqrDisplayed,
  prepareMmqrPayment,
} = require('../src/api');

const { invoiceMerchantQr } = require('../src/merchantQr');
// Synthetic, non-payable merchant. The expected checksums were calculated
// independently with binascii.crc_hqx over UTF-8 bytes.
const sticker = '00020101021126440011MM.COM.MMQR011500000000000000002060000005204074253031045802MM5911TEST CLINIC6006YANGON62100306STORE164150002my0105နမူနာ6304DEE0';
const invoiceQr = '00020101021226440011MM.COM.MMQR01150000000000000000206000000520407425303104540845000.005802MM5911TEST CLINIC6006YANGON62230109MMQR-QR-10306STORE164150002my0105နမူနာ63048D4D';

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
  assert.equal(payment.mmqr.qrPayload, undefined);
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

function configure(t, variables) {
  for (const [key, value] of Object.entries(variables)) {
    const old = process.env[key];
    t.after(() => { if (old === undefined) delete process.env[key]; else process.env[key] = old; });
    process.env[key] = value;
  }
}

test('personal checkout preserves the uploaded receive QR across invoice amounts and requires staff reconciliation', async t => {
  configure(t, { KBZPAY_QR_MODE: '', MMQR_PROVIDER_QR_ENDPOINT: 'https://unused.example' });
  const neverCall = () => assert.fail('Personal transfers do not call an acquiring provider');
  const issue = amount => prepareMmqrPayment(createMmqrPayment({ ...invoice(), amount }, actor), neverCall);
  const first = await issue(1200);
  const second = await issue(45000);
  assert.equal(first.mmqr.providerMode, 'kbzpay_personal');
  assert.equal(first.mmqr.payloadHash, 'f0a2ce9a2184a886fdea010def612ef1c1a1064578ff371c322294af0e860258');
  assert.equal(first.mmqr.qrPayload, second.mmqr.qrPayload);
  assert.equal(first.mmqr.qrImageDataUrl, second.mmqr.qrImageDataUrl);
  assert.notEqual(first.mmqr.reference, second.mmqr.reference);
  assert.equal(second.mmqr.amount, 45000);
  assert.equal(second.mmqr.recipientLabel, 'Sitt Yan Htun (…2067)');
  assert.equal(second.status, 'Pending');
  const input = { reference: second.mmqr.reference, amount: 45000 };
  assert.throws(() => settleMmqrPayment(second, input, actor), /reconcile/);
  assert.equal(reconcileMmqrPayment(second, { ...input, receiptReference: 'TEST-TX', note: 'Matched received transfer' }, actor).status, 'Paid');
});

test('checkout encodes the verified MMK total and bill number with the original merchant routing', async t => {
  configure(t, { KBZPAY_QR_MODE: 'merchant', MMQR_PROVIDER_QR_ENDPOINT: '', MMQR_MERCHANT_QR: sticker });
  const pending = createMmqrPayment(invoice(), actor, { reference: 'MMQR-QR-1' });
  const rendered = await prepareMmqrPayment(pending);
  assert.equal(rendered.status, 'Pending');
  assert.equal(rendered.mmqr.qrPayload, invoiceQr);
  assert.equal(rendered.mmqr.providerMode, 'merchant_mmqr');
  assert.match(rendered.mmqr.qrImageDataUrl, /^data:image\/png;base64,/);
  assert.equal(rendered.mmqr.payloadHash, crypto.createHash('sha256').update(invoiceQr).digest('hex'));
  const other = invoiceMerchantQr(sticker, 1200, 'MMQR-QR-2');
  assert.ok(other.includes('54071200.00'));
  assert.ok(other.includes('0109MMQR-QR-2'));
  assert.notEqual(other.slice(-4), invoiceQr.slice(-4));
});

test('missing configuration, damaged stickers and single-use QRs never generate a customer QR', async t => {
  configure(t, { KBZPAY_QR_MODE: 'merchant', MMQR_PROVIDER_QR_ENDPOINT: '', MMQR_MERCHANT_QR: '' });
  const pending = createMmqrPayment(invoice(), actor);
  await assert.rejects(prepareMmqrPayment(pending), /not configured/);
  for (const qr of [sticker.replace('TEST CLINIC', 'FAKE CLINIC'), invoiceQr, 'https://example.com/personal-qr']) {
    assert.throws(() => invoiceMerchantQr(qr, 1, 'MMQR-1'), error => error.status === 503);
  }
  assert.throws(() => invoiceMerchantQr(sticker, 10000000000, 'MMQR-1'), error => error.status === 400);
});

test('configured acquirer gets the exact invoice amount and its validated QR is rendered unchanged', async t => {
  configure(t, { KBZPAY_QR_MODE: 'merchant', MMQR_PROVIDER_QR_ENDPOINT: 'https://acquirer.example/qr', MMQR_PROVIDER_API_KEY: 'fixture',
    MMQR_MERCHANT_ID: 'MERCHANT-1', MMQR_MERCHANT_QR: sticker });
  const pending = createMmqrPayment(invoice(), actor, { reference: 'MMQR-QR-1', attemptId: 'MMA-ACQ-1' });
  const reply = (qrPayload, reference = pending.mmqr.reference) => async (url, options) => {
    assert.equal(options.headers['Idempotency-Key'], 'MMA-ACQ-1');
    assert.equal(JSON.parse(options.body).amount, 45000);
    assert.equal(JSON.parse(options.body).currency, 'MMK');
    return { ok: true, async json() { return { qrPayload, reference }; } };
  };
  const prepared = await prepareMmqrPayment(pending, reply(invoiceQr));
  assert.equal(prepared.mmqr.providerMode, 'acquirer_api');
  assert.equal(prepared.mmqr.qrPayload, invoiceQr);
  assert.match(prepared.mmqr.qrImageDataUrl, /^data:image\/png;base64,/);
  await assert.rejects(prepareMmqrPayment(pending, reply(invoiceQr, 'WRONG')), /reference/);
  await assert.rejects(prepareMmqrPayment(pending, reply(sticker)), /invoice amount/);
  await assert.rejects(prepareMmqrPayment(pending, reply(invoiceMerchantQr(sticker, 1, 'MMQR-QR-1'))), /invoice amount/);
  await assert.rejects(prepareMmqrPayment(pending, reply('MMQR|merchant=test')), /wallet payment/);
  const walletOrder = 'https://wallet.example/pay/per-order-token';
  assert.equal((await prepareMmqrPayment(pending, reply(walletOrder))).mmqr.qrPayload, walletOrder);
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

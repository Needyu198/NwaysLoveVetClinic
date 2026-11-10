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
  assert.equal(paid.auditTrail.at(-1).action, 'mmqr.provider_settled');
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
  assert.equal(paid.auditTrail.at(-1).action, 'mmqr.staff_reconciled');
  assert.equal(paid.auditTrail.at(-1).details.receiptReference, 'RECEIPT-99');
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

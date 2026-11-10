const { test } = require('node:test');
const assert = require('node:assert/strict');
const { reserveProductOrderInventory, createProductOrderPayment } = require('../src/api');

test('checkout verifies price and reserves unexpired inventory batches', async () => {
  const row = {
    id: 'inventory-row',
    data: {
      key: 'MED-1',
      value: {
        id: 'MED-1',
        name: 'Clinic Medicine',
        quantity: 7,
        sellingPrice: 2500,
        archived: false,
        batches: [
          { batchNumber: 'EARLY', quantity: 3, expiresOn: '2099-01-01T00:00:00.000Z' },
          { batchNumber: 'LATE', quantity: 4, expiresOn: '2099-06-01T00:00:00.000Z' },
        ],
        movements: [],
      },
    },
  };
  const updates = [];
  const client = {
    async query(sql, values) {
      if (sql.includes("FROM inventory WHERE data->'value'->>'id'")) {
        return { rows: [row] };
      }
      if (sql.startsWith('UPDATE inventory')) {
        updates.push(values[1]);
        return { rows: [] };
      }
      throw new Error(`Unexpected SQL: ${sql}`);
    },
  };
  const order = {
    items: [{ inventoryId: 'MED-1', name: 'Forged', unitPrice: 1, quantity: 4 }],
    total: 4,
  };

  await reserveProductOrderInventory(client, order, 'ORD-1');

  assert.equal(order.total, 10000);
  assert.deepEqual(order.items, [{
    inventoryId: 'MED-1', name: 'Clinic Medicine', unitPrice: 2500, quantity: 4,
  }]);
  assert.equal(updates[0].value.quantity, 3);
  assert.equal(updates[0].value.batches[0].quantity, 0);
  assert.equal(updates[0].value.batches[1].quantity, 3);
  assert.equal(updates[0].value.movements[0].reference, 'ORD-1');
});

test('MMQR checkout creates a pending amount-bound auditable payment', () => {
  const payment = createProductOrderPayment({
    id: 'ORD-1',
    ownerName: 'Pet Owner',
    total: 10000,
    paymentMethod: 'MMQR',
  }, { actorId: 'owner-1', actorRole: 'petOwner' });

  assert.equal(payment.id, 'PAY-ORD-1');
  assert.equal(payment.orderId, 'ORD-1');
  assert.equal(payment.amount, 10000);
  assert.equal(payment.status, 'Pending');
  assert.equal(payment.mmqr.amount, 10000);
  assert.equal(payment.auditTrail[0].action, 'mmqr.created');
});

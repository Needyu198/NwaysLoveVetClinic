import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  test('barcode and batches survive inventory serialization', () {
    final item = InventoryItem(
      id: 'MED-BARCODE',
      name: 'Test medicine',
      category: 'Medicine',
      quantity: 8,
      reorderLevel: 2,
      unit: 'boxes',
      expiresOn: DateTime(2031, 1, 1),
      barcode: '9551234567890',
      batches: [
        InventoryBatch(
          batchNumber: 'B-100',
          quantity: 8,
          expiresOn: DateTime(2031, 1, 1),
        ),
      ],
    );

    final restored = InventoryItem.fromDb(item.toDb());

    expect(restored.barcode, '9551234567890');
    expect(restored.batches.single.batchNumber, 'B-100');
    expect(restored.batches.single.quantity, 8);
  });

  test('stock out uses unexpired batches in earliest-expiry order', () {
    final item = InventoryItem(
      id: 'MED-FEFO',
      name: 'FEFO medicine',
      category: 'Medicine',
      quantity: 12,
      reorderLevel: 2,
      unit: 'boxes',
      expiresOn: DateTime(2032),
      batches: [
        InventoryBatch(
          batchNumber: 'LATE',
          quantity: 6,
          expiresOn: DateTime(2032),
        ),
        InventoryBatch(
          batchNumber: 'EARLY',
          quantity: 4,
          expiresOn: DateTime(2030),
        ),
        InventoryBatch(
          batchNumber: 'EXPIRED',
          quantity: 2,
          expiresOn: DateTime(2020),
        ),
      ],
    );

    final ok = StaffOperationsStore.instance.stockOut(
      item,
      5,
      reason: 'Clinic use',
    );

    expect(ok, isTrue);
    expect(item.quantity, 7);
    expect(
      item.batches.firstWhere((b) => b.batchNumber == 'EARLY').quantity,
      0,
    );
    expect(item.batches.firstWhere((b) => b.batchNumber == 'LATE').quantity, 5);
    expect(
      item.batches.firstWhere((b) => b.batchNumber == 'EXPIRED').quantity,
      2,
    );
    expect(item.movements.single.batchNumber, 'EARLY:4, LATE:1');
  });

  test('expired stock cannot be issued', () {
    final item = InventoryItem(
      id: 'MED-EXPIRED',
      name: 'Expired medicine',
      category: 'Medicine',
      quantity: 3,
      reorderLevel: 1,
      unit: 'boxes',
      expiresOn: DateTime(2020),
      batches: [
        InventoryBatch(
          batchNumber: 'OLD',
          quantity: 3,
          expiresOn: DateTime(2020),
        ),
      ],
    );

    expect(
      StaffOperationsStore.instance.stockOut(item, 1, reason: 'Clinic use'),
      isFalse,
    );
    expect(item.quantity, 3);
  });
}

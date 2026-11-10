import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/staff/staff_portal.dart';
import 'package:senior_project/pet_owner/pet_products_page.dart';

void main() {
  test('MMQR payment details and audit history survive database hydration', () {
    final payment = StaffPayment.fromDb({
      'id': 'INV-100',
      'owner': 'Owner',
      'pet': 'Pet',
      'amount': 45000,
      'status': 'Pending',
      'paymentMethod': 'MMQR',
      'mmqr': {
        'reference': 'MMQR-TEST-100',
        'amount': 45000,
        'currency': 'MMK',
        'status': 'Pending',
        'qrPayload': 'MMQR|invoice=INV-100',
        'createdAt': '2026-11-10T02:00:00.000Z',
        'expiresAt': '2026-11-10T02:15:00.000Z',
      },
      'auditTrail': [
        {
          'id': 'PAE-1',
          'at': '2026-11-10T02:00:00.000Z',
          'actorId': 'staff-1',
          'actorRole': 'staff',
          'action': 'mmqr.created',
          'fromStatus': 'Unpaid',
          'toStatus': 'Pending',
          'details': {'reference': 'MMQR-TEST-100', 'amount': 45000},
        },
      ],
    });

    expect(payment.hasPendingMmqr, isTrue);
    expect(payment.mmqr?.reference, 'MMQR-TEST-100');
    expect(payment.auditTrail.single.action, 'mmqr.created');
    expect(payment.toDb()['auditTrail'], hasLength(1));
  });

  test('product order keeps its generated MMQR checkout reference', () {
    final order = ProductOrder.fromDb({
      'id': 'ORD-1',
      'createdAt': '2026-11-10T02:00:00.000Z',
      'items': <Map<String, dynamic>>[],
      'total': 10000,
      'ownerName': 'Owner',
      'ownerPhone': '091234567',
      'paymentMethod': 'MMQR',
      'paymentId': 'PAY-ORD-1',
      'paymentStatus': 'Pending',
      'mmqr': {
        'reference': 'MMQR-ORDER-1',
        'amount': 10000,
        'qrPayload': 'MMQR|invoice=PAY-ORD-1',
      },
      'status': 'Reserved',
    });

    expect(order.paymentMethod, 'MMQR');
    expect(order.paymentStatus, 'Pending');
    expect(order.mmqr['reference'], 'MMQR-ORDER-1');
    expect(order.toDb()['paymentId'], 'PAY-ORD-1');
  });
}

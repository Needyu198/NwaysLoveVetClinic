import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/clinic_phone.dart';

void main() {
  test('clinic phone launcher opens a normalized tel URI', () async {
    Uri? launchedUri;

    final opened = await openClinicPhoneApp(
      '09-531 2717',
      launcher: (uri) async {
        launchedUri = uri;
        return true;
      },
    );

    expect(opened, isTrue);
    expect(launchedUri, Uri.parse('tel:095312717'));
  });

  test(
    'clinic phone launcher reports an unavailable phone application',
    () async {
      final opened = await openClinicPhoneApp(
        '09-5312717',
        launcher: (_) async => false,
      );

      expect(opened, isFalse);
    },
  );
}

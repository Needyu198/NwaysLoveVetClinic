import 'package:url_launcher/url_launcher.dart';

typedef PhoneUriLauncher = Future<bool> Function(Uri uri);

Uri clinicPhoneUri(String phoneNumber) {
  final normalized = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  return Uri(scheme: 'tel', path: normalized);
}

/// Opens the native phone application with [phoneNumber] ready to dial.
/// Returns false when the current device cannot handle telephone links.
Future<bool> openClinicPhoneApp(
  String phoneNumber, {
  PhoneUriLauncher? launcher,
}) async {
  final open =
      launcher ?? (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
  try {
    return await open(clinicPhoneUri(phoneNumber));
  } on Exception {
    return false;
  }
}

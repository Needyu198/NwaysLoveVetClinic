import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/clinic_api.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({this.initialIdentifier = '', super.key});

  final String initialIdentifier;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _requestKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  late final TextEditingController _identifier = TextEditingController(
    text: widget.initialIdentifier,
  );
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _codeRequested = false;
  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _notice;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!(_requestKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await ClinicApi.instance.requestPasswordReset(
        _identifier.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _notice = message;
      });
    } on ClinicApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not request a reset code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!(_resetKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ClinicApi.instance.resetPassword(
        identifier: _identifier.text.trim(),
        code: _code.text.trim(),
        newPassword: _password.text,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF159A68),
            size: 48,
          ),
          title: const Text('Password updated'),
          content: const Text(
            'Your password was reset successfully. Sign in with your new password.',
          ),
          actions: [
            FilledButton(
              key: const ValueKey('return-to-sign-in'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Return to Sign In'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ClinicApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not reset the password. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: LoginPage.backgroundColor,
    appBar: AppBar(
      backgroundColor: LoginPage.accentColor,
      foregroundColor: LoginPage.textColor,
      title: const Text(
        'Forgot Password',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Image.asset(LoginPage.logoAsset, width: 48, height: 48),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 72,
            color: Color(0xFF159A68),
          ),
          const SizedBox(height: 12),
          Text(
            _codeRequested
                ? 'Enter your verification code'
                : 'Recover your account',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            _codeRequested
                ? 'Use the six-digit code sent to the registered email. It expires after 10 minutes.'
                : 'Enter your registered email, username, or phone number. We will send a code to the email saved on your account.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 28),
          Form(
            key: _requestKey,
            child: TextFormField(
              key: const ValueKey('reset-identifier'),
              controller: _identifier,
              readOnly: _codeRequested,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              decoration: _inputDecoration(
                'Email, username, or phone number',
                Icons.person_search_rounded,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your registered account information'
                  : null,
            ),
          ),
          if (_notice != null) ...[
            const SizedBox(height: 16),
            _MessageBox(message: _notice!, error: false),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _MessageBox(message: _error!, error: true),
          ],
          const SizedBox(height: 22),
          if (!_codeRequested)
            FilledButton(
              key: const ValueKey('send-reset-code'),
              onPressed: _busy ? null : _requestCode,
              style: _primaryButtonStyle,
              child: _busy
                  ? const _ButtonSpinner()
                  : const Text('Send Verification Code'),
            )
          else
            Form(
              key: _resetKey,
              child: Column(
                children: [
                  TextFormField(
                    key: const ValueKey('reset-code'),
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: _inputDecoration(
                      'Six-digit verification code',
                      Icons.password_rounded,
                    ),
                    validator: (value) => value?.length == 6
                        ? null
                        : 'Enter the complete six-digit code',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('reset-new-password'),
                    controller: _password,
                    obscureText: !_showPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _passwordDecoration(
                      'New password',
                      _showPassword,
                      () => setState(() => _showPassword = !_showPassword),
                    ),
                    validator: (value) => (value?.length ?? 0) < 8
                        ? 'Use at least eight characters'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('reset-confirm-password'),
                    controller: _confirmPassword,
                    obscureText: !_showConfirmPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _passwordDecoration(
                      'Confirm new password',
                      _showConfirmPassword,
                      () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                    ),
                    validator: (value) => value != _password.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const ValueKey('confirm-password-reset'),
                    onPressed: _busy ? null : _resetPassword,
                    style: _primaryButtonStyle,
                    child: _busy
                        ? const _ButtonSpinner()
                        : const Text('Reset Password'),
                  ),
                  TextButton(
                    key: const ValueKey('request-another-code'),
                    onPressed: _busy ? null : _requestCode,
                    child: const Text('Send another code'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  static InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      );

  InputDecoration _passwordDecoration(
    String label,
    bool visible,
    VoidCallback toggle,
  ) => _inputDecoration(label, Icons.lock_outline_rounded).copyWith(
    suffixIcon: IconButton(
      onPressed: toggle,
      tooltip: visible ? 'Hide password' : 'Show password',
      icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
    ),
  );

  static final ButtonStyle _primaryButtonStyle = FilledButton.styleFrom(
    backgroundColor: const Color(0xFF17211E),
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(52),
    shape: const StadiumBorder(),
  );
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.error});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFFE9E8) : const Color(0xFFE5FAF1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: error ? const Color(0xFF9F201B) : const Color(0xFF116B4E),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 22,
    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
  );
}

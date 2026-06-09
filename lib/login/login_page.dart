import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const Color backgroundColor = Color(0xFFF6F8F7);
  static const Color accentColor = Color(0xFFA1FDD8);
  static const Color textColor = Color(0xFF000000);

  static const String logoAsset =
      "assets/photos/logoandphoto/Nway'sLoveLogo.png";
  static const String dogAsset = "assets/photos/logoandphoto/login_dog.png";
  static const String petsAsset = "assets/photos/logoandphoto/Nwaysphoto04.png";

  static const double designWidth = 440;
  static const double designHeight = 956;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / designWidth;
          final scaleY = constraints.maxHeight / designHeight;

          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 48 * scaleX,
                  top: 82 * scaleY,
                  width: 220 * scaleX,
                  height: 220 * scaleX,
                  child: Image.asset(logoAsset, fit: BoxFit.contain),
                ),
                Positioned(
                  left: 18 * scaleX,
                  top: 286 * scaleY,
                  width: 460 * scaleX,
                  height: 902 * scaleY,
                  child: Image.asset(dogAsset, fit: BoxFit.contain),
                ),
                Positioned(
                  left: 37 * scaleX,
                  right: 37 * scaleX,
                  bottom: 92 * scaleY,
                  height: 58 * scaleY,
                  child: const LoginActionButton(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LoginActionButton extends StatelessWidget {
  const LoginActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.28),
        builder: (context) => const SignInPanel(),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: LoginPage.accentColor.withValues(alpha: 0.82),
        foregroundColor: LoginPage.textColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const StadiumBorder(),
        padding: EdgeInsets.zero,
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Log in',
          style: TextStyle(
            color: LoginPage.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class SignInPanel extends StatelessWidget {
  const SignInPanel({super.key});

  static const Color panelColor = Color(0xB2A1FDD8);
  static const Color buttonColor = Color(0xFF2E2E2E);
  static const Color hintColor = Color(0xFFA7A7A7);

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.54,
        alignment: Alignment.bottomCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaleX = constraints.maxWidth / LoginPage.designWidth;
            final scaleY = constraints.maxHeight / 516;

            return ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(54 * scaleX),
              ),
              child: Material(
                color: panelColor,
                child: Stack(
                  children: [
                    Positioned(
                      left: -8 * scaleX,
                      right: -8 * scaleX,
                      bottom: 0,
                      height: 186 * scaleY,
                      child: Image.asset(
                        LoginPage.petsAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        79 * scaleX,
                        50 * scaleY,
                        79 * scaleX,
                        158 * scaleY,
                      ),
                      child: const SignInForm(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  bool _usePhoneNumber = false;

  @override
  Widget build(BuildContext context) {
    final contactLabel = _usePhoneNumber ? 'Phone Number' : 'Email or Username';
    final contactHint = _usePhoneNumber
        ? 'Enter your phone number'
        : 'Enter your Email or Username';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SignInLabel(contactLabel),
        const SizedBox(height: 10),
        SignInTextField(
          key: const ValueKey('contact-field'),
          hintText: contactHint,
          keyboardType: _usePhoneNumber
              ? TextInputType.phone
              : TextInputType.emailAddress,
          suffixIcon: _usePhoneNumber
              ? Icons.mail_outline_rounded
              : Icons.phone_iphone_rounded,
          suffixTooltip: _usePhoneNumber
              ? 'Use email or username'
              : 'Use phone number',
          onSuffixPressed: () {
            setState(() {
              _usePhoneNumber = !_usePhoneNumber;
            });
          },
        ),
        const SizedBox(height: 24),
        const SignInLabel('Password'),
        const SizedBox(height: 10),
        const SignInTextField(
          hintText: 'Enter your password',
          obscureText: true,
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: SignInPanel.buttonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: const StadiumBorder(),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: LoginPage.textColor,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 18,
                decoration: TextDecoration.underline,
                decorationColor: LoginPage.textColor,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SignInLabel extends StatelessWidget {
  const SignInLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: LoginPage.textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }
}

class SignInTextField extends StatelessWidget {
  const SignInTextField({
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.suffixTooltip,
    this.onSuffixPressed,
    super.key,
  });

  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final String? suffixTooltip;
  final VoidCallback? onSuffixPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: LoginPage.textColor,
          fontSize: 16,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: SignInPanel.hintColor,
            fontSize: 16,
            letterSpacing: 0,
          ),
          suffixIcon: suffixIcon == null
              ? null
              : IconButton(
                  tooltip: suffixTooltip,
                  onPressed: onSuffixPressed,
                  icon: Icon(
                    suffixIcon,
                    color: LoginPage.textColor,
                    size: 24,
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFD4D4D4), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: LoginPage.textColor, width: 2),
          ),
        ),
      ),
    );
  }
}

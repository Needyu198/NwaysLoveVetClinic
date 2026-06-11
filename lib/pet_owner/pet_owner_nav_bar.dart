import 'package:flutter/material.dart';

class PetOwnerNavBar extends StatelessWidget {
  const PetOwnerNavBar({super.key});

  static const Color _barColor = Color(0xFF2F2F2F);
  static const Color _iconColor = Color(0xFF8DB7AA);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(28, 0, 28, 12),
      child: SizedBox(
        height: 78,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _barColor,
            borderRadius: BorderRadius.circular(39),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                Expanded(child: _SelectedPetTab()),
                _NavIconButton(icon: Icons.medical_services_rounded),
                _NavIconButton(icon: Icons.shopping_basket_outlined),
                _NavIconButton(icon: Icons.account_circle_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPetTab extends StatelessWidget {
  const _SelectedPetTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: StadiumBorder(),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets_rounded, color: PetOwnerNavBar._iconColor),
              SizedBox(width: 10),
              Text(
                'My Pets',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, size: 36),
        color: _iconTint(icon),
        tooltip: _tooltip(icon),
      ),
    );
  }

  static Color _iconTint(IconData icon) {
    if (icon == Icons.medical_services_rounded) {
      return const Color(0xFFE64332);
    }
    return PetOwnerNavBar._iconColor;
  }

  static String _tooltip(IconData icon) {
    if (icon == Icons.medical_services_rounded) {
      return 'Appointments';
    }
    if (icon == Icons.shopping_basket_outlined) {
      return 'Shop';
    }
    return 'Profile';
  }
}

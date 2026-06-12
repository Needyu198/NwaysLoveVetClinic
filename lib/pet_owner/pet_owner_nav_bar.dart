import 'package:flutter/material.dart';

class PetOwnerNavBar extends StatelessWidget {
  const PetOwnerNavBar({super.key});

  static const Color _barColor = Color(0xFF2F2F2F);
  static const String pawIconAsset = 'assets/photos/icon/NwayIcon01.png';
  static const String medicalIconAsset = 'assets/photos/icon/NwayIcon02.png';
  static const String basketIconAsset = 'assets/photos/icon/NwayIcon03.png';
  static const String profileIconAsset = 'assets/photos/icon/NwayIcon04.png';

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
                _NavIconButton(
                  assetPath: PetOwnerNavBar.medicalIconAsset,
                  tooltip: 'Appointments',
                  size: 44,
                ),
                _NavIconButton(
                  assetPath: PetOwnerNavBar.basketIconAsset,
                  tooltip: 'Shop',
                  size: 36,
                ),
                _NavIconButton(
                  assetPath: PetOwnerNavBar.profileIconAsset,
                  tooltip: 'Profile',
                  size: 46,
                ),
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
              Image(
                image: AssetImage(PetOwnerNavBar.pawIconAsset),
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
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
  const _NavIconButton({
    required this.assetPath,
    required this.tooltip,
    required this.size,
  });

  final String assetPath;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        onPressed: () {},
        icon: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        tooltip: tooltip,
      ),
    );
  }
}

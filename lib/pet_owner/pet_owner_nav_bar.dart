import 'package:flutter/material.dart';

class PetOwnerNavBar extends StatelessWidget {
  const PetOwnerNavBar({
    this.selectedItem = PetOwnerNavItem.pets,
    this.onPetsTap,
    this.onAppointmentsTap,
    this.onShopTap,
    this.onProfileTap,
    super.key,
  });

  static const Color _barColor = Color(0xFF2F2F2F);
  static const String pawIconAsset = 'assets/photos/icon/NwayIcon01.png';
  static const String medicalIconAsset = 'assets/photos/icon/NwayIcon02.png';
  static const String basketIconAsset = 'assets/photos/icon/NwayIcon03.png';
  static const String profileIconAsset = 'assets/photos/icon/NwayIcon04.png';

  final PetOwnerNavItem selectedItem;
  final VoidCallback? onPetsTap;
  final VoidCallback? onAppointmentsTap;
  final VoidCallback? onShopTap;
  final VoidCallback? onProfileTap;

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
              children: [
                Expanded(
                  child: _NavTabButton(
                    assetPath: pawIconAsset,
                    label: 'My Pets',
                    selected: selectedItem == PetOwnerNavItem.pets,
                    onTap: onPetsTap,
                    iconSize: 34,
                  ),
                ),
                _NavIconButton(
                  assetPath: medicalIconAsset,
                  label: 'Clinic',
                  size: 44,
                  selected: selectedItem == PetOwnerNavItem.appointments,
                  onTap: onAppointmentsTap,
                ),
                Expanded(
                  child: _NavTabButton(
                    assetPath: basketIconAsset,
                    label: 'Products',
                    selected: selectedItem == PetOwnerNavItem.shop,
                    onTap: onShopTap,
                    iconSize: 32,
                  ),
                ),
                Expanded(
                  child: _NavTabButton(
                    assetPath: profileIconAsset,
                    label: 'Profile',
                    selected: selectedItem == PetOwnerNavItem.profile,
                    onTap: onProfileTap,
                    iconSize: 34,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum PetOwnerNavItem { pets, appointments, shop, profile }

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.assetPath,
    required this.label,
    required this.selected,
    required this.iconSize,
    this.onTap,
  });

  final String assetPath;
  final String label;
  final bool selected;
  final double iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return IconButton(
        onPressed: onTap,
        icon: Image.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
        tooltip: label,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 56,
        decoration: const ShapeDecoration(
          color: Colors.white,
          shape: StadiumBorder(),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image(
                  image: AssetImage(assetPath),
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
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
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.assetPath,
    required this.label,
    required this.size,
    required this.selected,
    this.onTap,
  });

  final String assetPath;
  final String label;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Expanded(
        flex: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 56,
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: StadiumBorder(),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image(
                      image: AssetImage(assetPath),
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
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
          ),
        ),
      );
    }

    return Expanded(
      child: IconButton(
        onPressed: onTap,
        icon: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        tooltip: label,
      ),
    );
  }
}

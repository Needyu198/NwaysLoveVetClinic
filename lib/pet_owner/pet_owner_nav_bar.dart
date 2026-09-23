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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavTabButton(
                  assetPath: pawIconAsset,
                  label: 'My Pets',
                  selected: selectedItem == PetOwnerNavItem.pets,
                  onTap: onPetsTap,
                  iconSize: 34,
                ),
                _NavTabButton(
                  assetPath: medicalIconAsset,
                  label: 'Clinic',
                  iconSize: 34,
                  selected: selectedItem == PetOwnerNavItem.appointments,
                  onTap: onAppointmentsTap,
                ),
                _NavTabButton(
                  assetPath: basketIconAsset,
                  label: 'Products',
                  selected: selectedItem == PetOwnerNavItem.shop,
                  onTap: onShopTap,
                  iconSize: 32,
                ),
                _NavTabButton(
                  assetPath: profileIconAsset,
                  label: 'Profile',
                  selected: selectedItem == PetOwnerNavItem.profile,
                  onTap: onProfileTap,
                  iconSize: 34,
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

/// Replaces one pet-owner root tab with another using navigation direction.
/// Tabs to the left enter from the left; tabs to the right enter from the right.
void navigatePetOwnerTab(
  BuildContext context, {
  required PetOwnerNavItem from,
  required PetOwnerNavItem to,
  required String routeName,
  required WidgetBuilder builder,
}) {
  if (from == to) return;
  final enteringFromLeft = to.index < from.index;
  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      settings: RouteSettings(name: routeName),
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final position =
            Tween<Offset>(
              begin: Offset(enteringFromLeft ? -1 : 1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            );
        return SlideTransition(position: position, child: child);
      },
    ),
  );
}

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
      return Expanded(
        child: IconButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Image.asset(
            assetPath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
          tooltip: label,
        ),
      );
    }

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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(
                    image: AssetImage(assetPath),
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
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
}

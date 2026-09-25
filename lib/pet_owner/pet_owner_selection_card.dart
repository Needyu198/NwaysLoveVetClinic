import 'package:flutter/material.dart';

/// Shared veterinarian-style card for pet-owner booking selections.
class PetOwnerSelectionCard extends StatelessWidget {
  const PetOwnerSelectionCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.showSelectionIndicator = true,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  static const green = Color(0xFF177D58);
  static const mint = Color(0xFFE8FFF5);
  static const muted = Color(0xFF6D7C77);

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final bool showSelectionIndicator;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? mint : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? green : const Color(0xFFDDE9E4),
              width: selected ? 2.3 : 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0B2F25),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: showSelectionIndicator ? 32 : 0,
                ),
                child: child,
              ),
              if (showSelectionIndicator)
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: ValueKey(selected),
                      color: selected ? green : muted,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

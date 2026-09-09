import 'package:flutter/material.dart';

import 'pet_owner_home_page.dart';

/// Shared pet-owner page header, styled to match the Book Appointment page:
/// a rounded mint banner with a back button, page title, and the clinic logo.
///
/// Use this at the top of a page's body (inside SafeArea) so queue, home visit,
/// emergency, history, first aid, and contact pages all share one look.
class PetOwnerPageHeader extends StatelessWidget {
  const PetOwnerPageHeader({
    required this.title,
    this.onBack,
    this.actions,
    super.key,
  });

  static const Color mint = Color(0xFFC5F7E3);

  final String title;

  /// Called when the back button is tapped. Defaults to popping the route.
  final VoidCallback? onBack;

  /// Optional trailing actions placed before the logo (e.g. history icon).
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 16, 16),
      decoration: const BoxDecoration(
        color: mint,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Back',
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF17211E),
              ),
            ),
          ),
          ...?actions,
          const SizedBox(width: 4),
          Image.asset(
            PetOwnerHomePage.logoAsset,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

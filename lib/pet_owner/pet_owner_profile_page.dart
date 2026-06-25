import 'package:flutter/material.dart';

import 'pet_owner_clinic_page.dart';
import 'pet_owner_home_page.dart';
import 'pet_owner_nav_bar.dart';
import 'pet_owner_profile_styles.dart';
import 'pet_products_page.dart';

class PetOwnerProfilePage extends StatelessWidget {
  const PetOwnerProfilePage({super.key});

  static const String routeName = '/pet-owner-profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetOwnerProfileStyles.pageBackground,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _ProfileHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 128),
                sliver: SliverList.list(
                  children: const [
                    _OwnerInfoCard(),
                    SizedBox(height: 22),
                    _QuickActions(),
                    SizedBox(height: 22),
                    _MyPetsSection(),
                    SizedBox(height: 16),
                    _FeatureSection(
                      title: 'Appointment',
                      children: [
                        _FeatureRow(
                          icon: Icons.event_available_rounded,
                          title: 'Upcoming Appointment',
                          subtitle: 'View your next clinic visit',
                          color: Color(0xFF2F80FF),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _FeatureSection(
                      title: 'Medical Summary',
                      children: [
                        _FeatureRow(
                          icon: Icons.verified_rounded,
                          title: 'Vaccines',
                          color: Color(0xFF18A77B),
                        ),
                        _FeatureRow(
                          icon: Icons.medication_rounded,
                          title: 'Treatments',
                          color: Color(0xFF8B3DFF),
                        ),
                        _FeatureRow(
                          icon: Icons.assignment_rounded,
                          title: 'Records',
                          color: Color(0xFF69717F),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _FeatureSection(
                      title: 'Reminders',
                      children: [
                        _FeatureRow(
                          icon: Icons.alarm_rounded,
                          title: 'Vaccine',
                          color: Color(0xFFEF5B4E),
                        ),
                        _FeatureRow(
                          icon: Icons.medication_liquid_rounded,
                          title: 'Medication',
                          color: Color(0xFF2F80FF),
                        ),
                        _FeatureRow(
                          icon: Icons.content_cut_rounded,
                          title: 'Grooming',
                          color: Color(0xFF8B3DFF),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _FeatureSection(
                      title: 'Orders',
                      children: [
                        _FeatureRow(
                          icon: Icons.shopping_bag_rounded,
                          title: 'Current Orders',
                          color: Color(0xFF18A77B),
                        ),
                        _FeatureRow(
                          icon: Icons.history_rounded,
                          title: 'Order History',
                          color: Color(0xFF69717F),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _FeatureSection(
                      title: 'Account',
                      children: [
                        _FeatureRow(
                          icon: Icons.credit_card_rounded,
                          title: 'Payment Methods',
                          color: Color(0xFF2F80FF),
                        ),
                        _FeatureRow(
                          icon: Icons.location_on_rounded,
                          title: 'Saved Address',
                          color: Color(0xFF18A77B),
                        ),
                        _FeatureRow(
                          icon: Icons.notifications_rounded,
                          title: 'Notification Settings',
                          color: Color(0xFFEF5B4E),
                        ),
                        _FeatureRow(
                          icon: Icons.support_agent_rounded,
                          title: 'Help & Support',
                          color: Color(0xFF8B3DFF),
                        ),
                        _FeatureRow(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          color: Color(0xFF69717F),
                        ),
                        _FeatureRow(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          color: Color(0xFFFF1E17),
                          destructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PetOwnerNavBar(
              selectedItem: PetOwnerNavItem.profile,
              onPetsTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetOwnerHomePage.routeName);
              },
              onShopTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetProductsPage.routeName);
              },
              onAppointmentsTap: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(PetOwnerClinicPage.routeName);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
        child: Row(
          children: [
            Image.asset(
              PetOwnerHomePage.logoAsset,
              width: 94,
              height: 94,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: PetOwnerProfileStyles.ink,
                fixedSize: const Size(48, 48),
              ),
              tooltip: 'Edit Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerInfoCard extends StatelessWidget {
  const _OwnerInfoCard();

  @override
  Widget build(BuildContext context) {
    return _MintPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 132,
                height: 164,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF7C958E),
                  size: 82,
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nee Yu', style: PetOwnerProfileStyles.name),
                SizedBox(height: 12),
                _ContactLine(
                  icon: Icons.phone_in_talk_rounded,
                  text: '09xxxxxxxx',
                ),
                SizedBox(height: 9),
                _ContactLine(
                  icon: Icons.email_outlined,
                  text: 'neeyu@email.com',
                ),
                SizedBox(height: 9),
                _ContactLine(icon: Icons.home_rounded, text: 'NPW'),
                SizedBox(height: 18),
                _EditProfileButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: StadiumBorder(),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PetOwnerProfileStyles.contact,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text('Edit Profile'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF69717F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: PetOwnerProfileStyles.sectionTitle),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.phone_in_talk_rounded,
                label: 'Emergency',
                color: Color(0xFFFF000F),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.location_on_rounded,
                label: 'Location',
                color: Color(0xFF4167D8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PetOwnerProfileStyles.mint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 43),
          ),
          const SizedBox(height: 12),
          Text(label, style: PetOwnerProfileStyles.cardTitle),
        ],
      ),
    );
  }
}

class _MyPetsSection extends StatelessWidget {
  const _MyPetsSection();

  @override
  Widget build(BuildContext context) {
    return _FeatureSection(
      title: 'My Pets',
      action: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Pet'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF16785B),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      children: const [
        _PetRow(
          icon: Icons.pets_rounded,
          title: 'Max',
          subtitle: 'Dog',
          color: Color(0xFF2F80FF),
        ),
        _PetRow(
          icon: Icons.cruelty_free_rounded,
          title: 'Luna',
          subtitle: 'Cat',
          color: Color(0xFF8B3DFF),
        ),
      ],
    );
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _FeatureRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({
    required this.title,
    required this.children,
    this.action,
  });

  final String title;
  final Widget? action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PetOwnerProfileStyles.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100B2F25),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: PetOwnerProfileStyles.sectionTitle),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 8),
          for (final child in children) child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final titleColor = destructive ? const Color(0xFFFF1E17) : Colors.black;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PetOwnerProfileStyles.rowTitle.copyWith(
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: PetOwnerProfileStyles.cardSubtitle),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A8A1),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _MintPanel extends StatelessWidget {
  const _MintPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PetOwnerProfileStyles.mint,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: child,
    );
  }
}

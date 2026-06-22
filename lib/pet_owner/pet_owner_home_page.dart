import 'package:flutter/material.dart';

import 'pet_owner_nav_bar.dart';
import 'pet_owner_profile_page.dart';
import 'pet_profile_page.dart';
import 'pet_products_page.dart';

class PetOwnerHomePage extends StatelessWidget {
  const PetOwnerHomePage({super.key});

  static const String routeName = '/pet-owner-home';

  static const Color mintColor = Color(0xFFA1FDD8);
  static const Color softMintColor = Color(0xFFD7FCEB);
  static const Color pageColor = Color(0xFFF7FAF8);
  static const Color inkColor = Color(0xFF17211E);
  static const Color mutedTextColor = Color(0xFF60756E);
  static const Color textColor = Color(0xFF000000);
  static const String logoAsset =
      'assets/photos/logoandphoto/nways_love_logo.png';
  static const String petsAsset = 'assets/photos/logoandphoto/pets_row.png';
  static const String dogAsset = 'assets/photos/logoandphoto/nways_photo.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      body: Stack(
        children: [
          const _HomeContent(),
          Align(
            alignment: Alignment.bottomCenter,
            child: PetOwnerNavBar(
              onProfileTap: () {
                Navigator.of(context).pushNamed(PetOwnerProfilePage.routeName);
              },
              onShopTap: () {
                Navigator.of(context).pushNamed(PetProductsPage.routeName);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  static const _reminders = <_HomeMessage>[
    _HomeMessage(
      title: 'Morning medicine',
      detail:
          'Time to give Max his medication. Don’t forget his morning dose to keep him healthy and active.',
      meta: '8:00 AM',
      icon: Icons.medication_liquid_rounded,
    ),
    _HomeMessage(
      title: 'Vaccination due',
      detail: 'Max’s vaccination is due this week. Schedule a visit soon.',
      meta: 'This week',
      icon: Icons.vaccines_rounded,
    ),
    _HomeMessage(
      title: 'Dinner time',
      detail: 'Feeding time for Max. Give him his evening meal.',
      meta: '6:00 PM',
      icon: Icons.restaurant_rounded,
    ),
  ];

  static const _appointments = <_HomeMessage>[
    _HomeMessage(
      title: 'Grooming',
      detail:
          'Max has a grooming appointment tomorrow. Please arrive 10 minutes early.',
      meta: 'Tomorrow, 10:00 AM',
      icon: Icons.content_cut_rounded,
    ),
    _HomeMessage(
      title: 'Annual checkup',
      detail: 'Bella’s annual checkup is scheduled with the clinic team.',
      meta: 'Friday, 2:30 PM',
      icon: Icons.event_available_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _HeroPetSection()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 124),
          sliver: SliverList.list(
            children: [
              const _SectionTitle(
                title: 'Reminders',
                subtitle: 'Care tasks today',
              ),
              const SizedBox(height: 14),
              for (final reminder in _reminders) ...[
                _HomeMessageCard(message: reminder),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 10),
              const _SectionTitle(
                title: 'Appointments',
                subtitle: 'Upcoming clinic visits',
              ),
              const SizedBox(height: 14),
              for (final appointment in _appointments) ...[
                _HomeMessageCard(message: appointment),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroPetSection extends StatelessWidget {
  const _HeroPetSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA1FDD8), Color(0xFFC9F7E4), Color(0xFFE8FFF4)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
        boxShadow: [
          BoxShadow(
            color: Color(0x240B2F25),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.46),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Image(
                        image: AssetImage(PetOwnerHomePage.logoAsset),
                        width: 94,
                        height: 94,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const _ProfilePhoto(),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Pets',
                    style: TextStyle(
                      color: PetOwnerHomePage.inkColor,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Healthy days start here',
                    style: TextStyle(
                      color: PetOwnerHomePage.mutedTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(height: 224, child: _PetCarousel()),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B2F25),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 54,
        color: Color(0xFF637A74),
      ),
    );
  }
}

class _PetCarousel extends StatelessWidget {
  const _PetCarousel();

  static const _pets = <PetProfile>[
    PetProfile(
      name: 'Max',
      species: 'Dog',
      breed: 'Golden Retriever',
      sex: 'Male',
      weight: '18 kg',
      imageAsset: PetOwnerHomePage.dogAsset,
      imageAlignment: Alignment.center,
    ),
    PetProfile(
      name: 'Bella',
      species: 'Dog',
      breed: 'Shih Tzu',
      sex: 'Female',
      weight: '6 kg',
      imageAsset: PetOwnerHomePage.dogAsset,
      imageAlignment: Alignment.center,
    ),
    PetProfile(
      name: 'Luna',
      species: 'Dog',
      breed: 'Mixed breed',
      sex: 'Female',
      weight: '10 kg',
      imageAsset: PetOwnerHomePage.dogAsset,
      imageAlignment: Alignment.center,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 28, right: 28, bottom: 10),
      children: [
        for (final pet in _pets) ...[
          _PetCard(profile: pet),
          if (pet != _pets.last) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.profile});

  final PetProfile profile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(PetProfilePage.routeName, arguments: profile);
        },
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 174,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220B2F25),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  profile.imageAsset,
                  fit: BoxFit.cover,
                  alignment: profile.imageAlignment,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x33000000),
                        Color(0xA6000000),
                      ],
                      stops: [0.42, 0.7, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  right: 13,
                  bottom: 13,
                  child: Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
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
}

class _HomeMessage {
  const _HomeMessage({
    required this.title,
    required this.detail,
    required this.meta,
    required this.icon,
  });

  final String title;
  final String detail;
  final String meta;
  final IconData icon;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PetOwnerHomePage.inkColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: PetOwnerHomePage.mutedTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: PetOwnerHomePage.softMintColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFF5F8177),
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _HomeMessageCard extends StatelessWidget {
  const _HomeMessageCard({required this.message});

  final _HomeMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2F4EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B2F25),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: PetOwnerHomePage.softMintColor,
              shape: BoxShape.circle,
            ),
            child: Icon(message.icon, color: const Color(0xFF5F8177), size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        message.title,
                        style: const TextStyle(
                          color: PetOwnerHomePage.inkColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.meta,
                      style: const TextStyle(
                        color: Color(0xFFEF5B4E),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message.detail,
                  style: const TextStyle(
                    color: PetOwnerHomePage.mutedTextColor,
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

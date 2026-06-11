import 'package:flutter/material.dart';

import 'pet_owner_nav_bar.dart';

class PetOwnerHomePage extends StatelessWidget {
  const PetOwnerHomePage({super.key});

  static const String routeName = '/pet-owner-home';

  static const Color mintColor = Color(0xFFA1FDD8);
  static const Color textColor = Color(0xFF000000);
  static const String logoAsset =
      'assets/photos/logoandphoto/nways_love_logo.png';
  static const String petsAsset = 'assets/photos/logoandphoto/pets_row.png';
  static const String dogAsset = 'assets/photos/logoandphoto/nways_photo.png';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _HomeContent(),
          Align(
            alignment: Alignment.bottomCenter,
            child: PetOwnerNavBar(),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  static const _reminders = [
    '“Time to give Max his medication at 8:00 AM. Don’t forget his morning dose to keep him healthy and active.”',
    '“Max’s vaccination is due this week. Schedule a visit to keep him protected.”',
    '“Feeding time for Max! Give him his meal at 6:00 PM.”',
  ];

  static const _appointments = [
    '“Max has a grooming appointment tomorrow at 10:00 AM. Please arrive 10 minutes early.”',
    '“Bella’s annual checkup is scheduled for Friday at 2:30 PM.”',
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _HeroPetSection()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(32, 18, 32, 118),
          sliver: SliverList.list(
            children: [
              const _SectionTitle('Reminders'),
              const SizedBox(height: 22),
              for (final reminder in _reminders) ...[
                _MintMessage(text: reminder),
                const SizedBox(height: 20),
              ],
              const _SectionTitle('Appointments'),
              const SizedBox(height: 22),
              for (final appointment in _appointments) ...[
                _MintMessage(text: appointment),
                const SizedBox(height: 20),
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
      height: 492,
      decoration: const BoxDecoration(
        color: PetOwnerHomePage.mintColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(46, 12, 40, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Image(
                    image: AssetImage(PetOwnerHomePage.logoAsset),
                    width: 118,
                    height: 118,
                    fit: BoxFit.contain,
                  ),
                  Spacer(),
                  _ProfilePhoto(),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 47, top: 14),
              child: Text(
                'My Pets',
                style: TextStyle(
                  color: PetOwnerHomePage.textColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 25),
            const SizedBox(
              height: 205,
              child: _PetCarousel(),
            ),
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
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1718A8), width: 1.5),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 62,
        color: Color(0xFF637A74),
      ),
    );
  }
}

class _PetCarousel extends StatelessWidget {
  const _PetCarousel();

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 37, right: 28),
      children: const [
        _PetCard(
          name: 'Max',
          imageAsset: PetOwnerHomePage.petsAsset,
          alignment: Alignment(-0.23, 0),
        ),
        SizedBox(width: 24),
        _PetCard(
          name: 'Bella',
          imageAsset: PetOwnerHomePage.dogAsset,
          alignment: Alignment.center,
        ),
        SizedBox(width: 24),
        _PetCard(
          name: 'Luna',
          imageAsset: PetOwnerHomePage.petsAsset,
          alignment: Alignment(0.98, 0),
        ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.name,
    required this.imageAsset,
    required this.alignment,
  });

  final String name;
  final String imageAsset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: alignment,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 142,
                height: 46,
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: PetOwnerHomePage.mintColor.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: PetOwnerHomePage.textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: PetOwnerHomePage.textColor,
        fontSize: 34,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _MintMessage extends StatelessWidget {
  const _MintMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 19),
      decoration: BoxDecoration(
        color: PetOwnerHomePage.mintColor.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: PetOwnerHomePage.textColor,
          fontSize: 23,
          height: 1.18,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

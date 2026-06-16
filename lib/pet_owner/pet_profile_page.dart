import 'package:flutter/material.dart';

import 'pet_owner_home_page.dart';

class PetProfile {
  const PetProfile({
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.weight,
    required this.imageAsset,
    this.imageAlignment = Alignment.center,
  });

  final String name;
  final String species;
  final String breed;
  final String sex;
  final String weight;
  final String imageAsset;
  final Alignment imageAlignment;
}

class PetProfilePage extends StatelessWidget {
  const PetProfilePage({super.key});

  static const String routeName = '/pet-profile';

  static const PetProfile fallbackProfile = PetProfile(
    name: 'Max',
    species: 'Dog',
    breed: 'Golden Retriever',
    sex: 'Male',
    weight: '18 kg',
    imageAsset: PetOwnerHomePage.dogAsset,
  );

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final profile = args is PetProfile ? args : fallbackProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _ProfileHeader(profile: profile)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 26, 32, 36),
              sliver: SliverList.list(
                children: [
                  _PhotoPanel(profile: profile),
                  const SizedBox(height: 28),
                  _BasicInfoPanel(profile: profile),
                  const SizedBox(height: 32),
                  const _MedicalInfoPanel(),
                  const SizedBox(height: 32),
                  const _TextInfoPanel(
                    title: 'Appointment History',
                    lines: [
                      'Past visits',
                      'Doctor name',
                      'Date & time',
                      'Reason (Checkup, Emergency, etc.)',
                      'Status (Completed / Cancelled)',
                    ],
                  ),
                  const SizedBox(height: 32),
                  const _TextInfoPanel(
                    title: 'Treatment &\nPrescription Records',
                    lines: [
                      'Diagnosis',
                      'Treatment details',
                      'Prescribed medicines',
                      'Dosage instructions',
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Center(child: _EmergencyButton()),
                  const SizedBox(height: 42),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final PetProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.black,
            iconSize: 28,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Pet Profile',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel({required this.profile});

  final PetProfile profile;

  @override
  Widget build(BuildContext context) {
    return _MintPanel(
      height: 286,
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Image.asset(
              profile.imageAsset,
              fit: BoxFit.cover,
              alignment: profile.imageAlignment,
            ),
          ),
          Positioned(
            right: 28,
            top: 28,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: PetOwnerHomePage.softMintColor.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.black,
                size: 34,
              ),
            ),
          ),
          Positioned(
            left: 28,
            bottom: 24,
            child: Text(
              profile.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: [
                  Shadow(
                    color: Color(0x88000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoPanel extends StatelessWidget {
  const _BasicInfoPanel({required this.profile});

  final PetProfile profile;

  @override
  Widget build(BuildContext context) {
    return _MintPanel(
      padding: const EdgeInsets.fromLTRB(32, 30, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Basic Info', style: _PetProfileStyles.sectionTitle),
          const SizedBox(height: 24),
          Wrap(
            spacing: 28,
            runSpacing: 24,
            children: [
              _BasicInfoItem(
                icon: Icons.pets_rounded,
                label: 'Name',
                value: profile.name,
              ),
              _BasicInfoItem(
                icon: Icons.biotech_rounded,
                label: 'Breed',
                value: profile.breed,
              ),
              _BasicInfoItem(
                icon: Icons.cruelty_free_rounded,
                label: 'Species',
                value: profile.species,
              ),
              _BasicInfoItem(
                icon: Icons.monitor_weight_rounded,
                label: 'Weight',
                value: profile.weight,
              ),
              _BasicInfoItem(
                icon: Icons.transgender_rounded,
                label: 'Sex',
                value: profile.sex,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BasicInfoItem extends StatelessWidget {
  const _BasicInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFD7D7D7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black, size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _PetProfileStyles.infoLabel),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _PetProfileStyles.infoValue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalInfoPanel extends StatelessWidget {
  const _MedicalInfoPanel();

  @override
  Widget build(BuildContext context) {
    return _MintPanel(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Medical Info',
                  style: _PetProfileStyles.sectionTitle,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFDCDCDC),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                child: const Text('Edit Reminder'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _WhiteInfoBox(title: 'Vaccination history'),
          const SizedBox(height: 28),
          const _WhiteInfoBox(title: 'Upcoming vaccination schedule'),
          const SizedBox(height: 28),
          const _WhiteInfoBox(title: 'Allergies'),
        ],
      ),
    );
  }
}

class _WhiteInfoBox extends StatelessWidget {
  const _WhiteInfoBox({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 146),
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
      ),
      child: Text(title, style: _PetProfileStyles.boxTitle),
    );
  }
}

class _TextInfoPanel extends StatelessWidget {
  const _TextInfoPanel({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return _MintPanel(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _PetProfileStyles.sectionTitle),
          const SizedBox(height: 30),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(line, style: _PetProfileStyles.recordText),
            ),
        ],
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      height: 120,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFF1E17),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(38),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency_share_rounded, size: 34),
            SizedBox(height: 8),
            Text(
              'Emergency',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MintPanel extends StatelessWidget {
  const _MintPanel({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(28),
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: PetOwnerHomePage.softMintColor,
        borderRadius: BorderRadius.circular(36),
      ),
      child: child,
    );
  }
}

class _PetProfileStyles {
  static const sectionTitle = TextStyle(
    color: Colors.black,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.18,
  );

  static const infoLabel = TextStyle(
    color: Colors.black,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const infoValue = TextStyle(
    color: Color(0xFF394A45),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const boxTitle = TextStyle(
    color: Colors.black,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const recordText = TextStyle(
    color: Colors.black,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.22,
  );
}

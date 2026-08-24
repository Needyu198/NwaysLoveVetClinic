import 'package:flutter/material.dart';

import 'appointment_booking_page.dart';
import 'emergency_service_page.dart';
import 'pet_owner_clinic_page.dart';
import 'pet_owner_home_page.dart';
import 'pet_owner_nav_bar.dart';
import 'pet_owner_profile_styles.dart';
import 'pet_products_page.dart';
import 'pet_profile_page.dart';
import 'profile_flows.dart';
import 'profile_account_pages.dart';

class PetOwnerProfilePage extends StatefulWidget {
  const PetOwnerProfilePage({super.key});
  static const String routeName = '/pet-owner-profile';

  @override
  State<PetOwnerProfilePage> createState() => _PetOwnerProfilePageState();
}

class _PetOwnerProfilePageState extends State<PetOwnerProfilePage> {
  @override
  void initState() {
    super.initState();
    OwnerProfileStore.instance.addListener(_refresh);
    ProfilePetStore.instance.addListener(_refresh);
    AppointmentStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    OwnerProfileStore.instance.removeListener(_refresh);
    ProfilePetStore.instance.removeListener(_refresh);
    AppointmentStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final owner = OwnerProfileStore.instance.profile;
    return Scaffold(
      backgroundColor: PetOwnerProfileStyles.pageBackground,
      body: Stack(
        children: [
          CustomScrollView(
            key: const ValueKey('owner-profile-scroll'),
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(onEdit: () => _editProfile(context)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 128),
                sliver: SliverList.list(
                  children: [
                    _OwnerInfoCard(
                      owner: owner,
                      onEdit: () => _editProfile(context),
                    ),
                    const SizedBox(height: 22),
                    const _QuickActions(),
                    const SizedBox(height: 22),
                    _MyPetsSection(pets: ProfilePetStore.instance.pets),
                    const SizedBox(height: 16),
                    _UpcomingAppointmentsSection(
                      appointments: AppointmentStore.instance.appointments,
                    ),
                    const SizedBox(height: 16),
                    _FeatureSection(
                      title: 'Medical Summary',
                      children: [
                        _FeatureRow(
                          icon: Icons.verified_rounded,
                          title: 'Vaccines',
                          color: Color(0xFF18A77B),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const VaccinationSummaryPage(),
                            ),
                          ),
                        ),
                        _FeatureRow(
                          icon: Icons.medication_rounded,
                          title: 'Treatments',
                          color: Color(0xFF8B3DFF),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TreatmentHistoryPage(),
                            ),
                          ),
                        ),
                        _FeatureRow(
                          icon: Icons.assignment_rounded,
                          title: 'Records',
                          color: Color(0xFF69717F),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfileMedicalRecordsPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FeatureSection(
                      title: 'Account',
                      children: [
                        _FeatureRow(
                          icon: Icons.location_on_rounded,
                          title: 'Saved Addresses',
                          subtitle: owner.address,
                          color: const Color(0xFF18A77B),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SavedAddressesPage(),
                            ),
                          ),
                        ),
                        _FeatureRow(
                          icon: Icons.notifications_rounded,
                          title: 'Notification Settings',
                          color: Color(0xFFEF5B4E),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const NotificationSettingsPage(),
                            ),
                          ),
                        ),
                        _FeatureRow(
                          icon: Icons.support_agent_rounded,
                          title: 'Help & Support',
                          color: Color(0xFF8B3DFF),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const HelpSupportPage(),
                            ),
                          ),
                        ),
                        _FeatureRow(
                          icon: Icons.logout_rounded,
                          title: 'Log Out',
                          color: Color(0xFFFF1E17),
                          destructive: true,
                          onTap: () => confirmProfileLogout(context),
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
              onPetsTap: () => Navigator.of(
                context,
              ).pushReplacementNamed(PetOwnerHomePage.routeName),
              onShopTap: () => Navigator.of(
                context,
              ).pushReplacementNamed(PetProductsPage.routeName),
              onAppointmentsTap: () => Navigator.of(
                context,
              ).pushReplacementNamed(PetOwnerClinicPage.routeName),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EditOwnerProfilePage()),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SafeArea(
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
            key: const ValueKey('header-edit-profile'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              fixedSize: const Size(48, 48),
            ),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    ),
  );
}

class _OwnerInfoCard extends StatelessWidget {
  const _OwnerInfoCard({required this.owner, required this.onEdit});
  final OwnerProfileData owner;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => _MintPanel(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 104,
          height: 148,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(
            owner.photoSource == null
                ? Icons.person_rounded
                : Icons.person_pin_rounded,
            color: const Color(0xFF7C958E),
            size: 68,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(owner.fullName, style: PetOwnerProfileStyles.name),
              const SizedBox(height: 9),
              _ContactLine(
                icon: Icons.phone_in_talk_rounded,
                text: owner.phone,
              ),
              const SizedBox(height: 6),
              _ContactLine(icon: Icons.email_outlined, text: owner.email),
              const SizedBox(height: 6),
              _ContactLine(icon: Icons.home_rounded, text: owner.address),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('owner-edit-profile'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 17),
                label: const Text('Edit Profile'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PetOwnerProfileStyles.contact,
        ),
      ),
    ],
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Quick Actions', style: PetOwnerProfileStyles.sectionTitle),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              key: const ValueKey('profile-emergency-action'),
              icon: Icons.phone_in_talk_rounded,
              label: 'Emergency',
              color: const Color(0xFFFF000F),
              onTap: () => Navigator.of(
                context,
              ).pushNamed(EmergencyServicePage.routeName),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _QuickActionCard(
              key: const ValueKey('profile-location-action'),
              icon: Icons.location_on_rounded,
              label: 'Location',
              color: const Color(0xFF4167D8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ClinicLocationPage(),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: PetOwnerProfileStyles.mint,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 10),
            Text(label, style: PetOwnerProfileStyles.cardTitle),
          ],
        ),
      ),
    ),
  );
}

class _MyPetsSection extends StatelessWidget {
  const _MyPetsSection({required this.pets});
  final List<ProfilePet> pets;

  @override
  Widget build(BuildContext context) => _FeatureSection(
    title: 'My Pets',
    action: TextButton.icon(
      key: const ValueKey('profile-add-pet'),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AddPetPage())),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Pet'),
    ),
    children: pets
        .map(
          (pet) => _FeatureRow(
            key: ValueKey('profile-pet-${pet.name}'),
            icon: pet.type == 'Cat'
                ? Icons.cruelty_free_rounded
                : Icons.pets_rounded,
            title: pet.name,
            subtitle: '${pet.type} • ${pet.breed} • ${pet.ageYears} years',
            color: pet.type == 'Cat'
                ? const Color(0xFF8B3DFF)
                : const Color(0xFF2F80FF),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PetProfilePage(),
                settings: RouteSettings(arguments: pet.toPetProfile()),
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _UpcomingAppointmentsSection extends StatelessWidget {
  const _UpcomingAppointmentsSection({required this.appointments});
  final List<BookedAppointment> appointments;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final upcoming =
        appointments
            .where(
              (item) =>
                  item.status != 'Cancelled' &&
                  !DateUtils.dateOnly(item.date).isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return _FeatureSection(
      title: 'Upcoming Appointments',
      action: upcoming.isEmpty
          ? null
          : TextButton(
              key: const ValueKey('view-all-appointments'),
              onPressed: () =>
                  Navigator.of(context).pushNamed(MyAppointmentsPage.routeName),
              child: const Text('View All'),
            ),
      children: upcoming.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'No upcoming appointments',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('profile-book-appointment'),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(AppointmentBookingPage.routeName),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Book Appointment'),
              ),
            ]
          : upcoming
                .take(2)
                .map(
                  (appointment) =>
                      _UpcomingAppointmentCard(appointment: appointment),
                )
                .toList(),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard({required this.appointment});
  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('profile-appointment-${appointment.id}'),
    elevation: 0,
    color: const Color(0xFFF3FFF9),
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AppointmentDetailsPage(appointment: appointment),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${appointment.pet.name} • ${appointment.service.name}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Chip(
                  label: Text(appointment.status),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(appointment.veterinarian),
            Text('${_profileDate(appointment.date)} • ${appointment.time}'),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                OutlinedButton(
                  key: ValueKey('appointment-reminder-${appointment.id}'),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Reminder scheduled for ${appointment.pet.name}’s appointment',
                      ),
                    ),
                  ),
                  child: const Text('Set Reminder'),
                ),
                OutlinedButton(
                  key: ValueKey('appointment-reschedule-${appointment.id}'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          RescheduleAppointmentPage(appointment: appointment),
                    ),
                  ),
                  child: const Text('Reschedule'),
                ),
                TextButton(
                  key: ValueKey('appointment-cancel-${appointment.id}'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          BookingCancellationPage(appointment: appointment),
                    ),
                  ),
                  child: const Text('Cancel Booking'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: PetOwnerProfileStyles.border),
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
        ...children,
      ],
    ),
  );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.destructive = false,
    this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PetOwnerProfileStyles.rowTitle.copyWith(
                    color: destructive ? const Color(0xFFFF1E17) : null,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: PetOwnerProfileStyles.cardSubtitle),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _MintPanel extends StatelessWidget {
  const _MintPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: PetOwnerProfileStyles.mint,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: child,
  );
}

String _profileDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

import 'package:flutter/material.dart';

import 'appointment_booking_page.dart';
import 'owner_shared_stores.dart';
import 'pet_add_reminder_page.dart';
import 'pet_image.dart';
import 'pet_reminder_page.dart';
import 'profile_flows.dart';
import 'pet_owner_clinic_page.dart';
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
              onAppointmentsTap: () {
                Navigator.of(context).pushNamed(PetOwnerClinicPage.routeName);
              },
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

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final _reminderStore = ReminderStore.instance;
  final _appointmentStore = AppointmentStore.instance;

  @override
  void initState() {
    super.initState();
    _reminderStore.addListener(_onChanged);
    _appointmentStore.addListener(_onChanged);
  }

  @override
  void dispose() {
    _reminderStore.removeListener(_onChanged);
    _appointmentStore.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _dateLabel(DateTime d) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(d);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${_months[d.month - 1]} ${d.day}';
  }

  String _timeLabel(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  IconData _reminderIcon(ReminderType type) {
    switch (type) {
      case ReminderType.vaccine:
        return Icons.vaccines_rounded;
      case ReminderType.medicine:
        return Icons.medication_rounded;
      case ReminderType.checkup:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Real, DB-backed reminders (soonest first, not completed).
    final reminders = _reminderStore.upcoming;
    // Real, DB-backed upcoming appointments (not cancelled, not past).
    final today = DateUtils.dateOnly(DateTime.now());
    final appointments =
        _appointmentStore.appointments
            .where(
              (a) =>
                  a.status != 'Cancelled' &&
                  !DateUtils.dateOnly(a.date).isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _HeroPetSection()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 124),
          sliver: SliverList.list(
            children: [
              _SectionTitle(
                title: 'Reminders',
                subtitle: 'Care tasks',
                onSeeAll: () =>
                    Navigator.of(context).pushNamed(PetReminderPage.routeName),
              ),
              const SizedBox(height: 14),
              if (reminders.isEmpty)
                _EmptyHomeCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'No reminders yet',
                  detail:
                      'Add a reminder to stay on top of your pet\u2019s care.',
                  actionLabel: 'Add reminder',
                  onAction: () => Navigator.of(
                    context,
                  ).pushNamed(PetAddReminderPage.routeName),
                )
              else
                for (final r in reminders.take(4)) ...[
                  _HomeMessageCard(
                    message: _HomeMessage(
                      title: r.title,
                      detail: r.note.isNotEmpty
                          ? r.note
                          : (r.petName != null
                                ? 'For ${r.petName}'
                                : 'Scheduled reminder'),
                      meta:
                          '${_dateLabel(r.dateTime)} \u2022 ${_timeLabel(r.dateTime)}',
                      icon: _reminderIcon(r.type),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              const SizedBox(height: 10),
              _SectionTitle(
                title: 'Appointments',
                subtitle: 'Upcoming clinic visits',
                onSeeAll: () => Navigator.of(
                  context,
                ).pushNamed(MyAppointmentsPage.routeName),
              ),
              const SizedBox(height: 14),
              if (appointments.isEmpty)
                _EmptyHomeCard(
                  icon: Icons.event_available_rounded,
                  title: 'No upcoming appointments',
                  detail: 'Book a visit with the clinic for your pet.',
                  actionLabel: 'Book appointment',
                  onAction: () => Navigator.of(
                    context,
                  ).pushNamed(AppointmentBookingPage.routeName),
                )
              else
                for (final a in appointments.take(4)) ...[
                  _HomeMessageCard(
                    message: _HomeMessage(
                      title: '${a.pet.name} \u2022 ${a.service.name}',
                      detail: a.reason.isNotEmpty
                          ? a.reason
                          : 'With ${a.veterinarian}',
                      meta: '${_dateLabel(a.date)} \u2022 ${a.time}',
                      icon: Icons.event_available_rounded,
                    ),
                  ),
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
          mainAxisSize: MainAxisSize.min,
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
                  const _NotificationBell(),
                  const SizedBox(width: 12),
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
            const SizedBox(height: 18),
            const SizedBox(height: 200, child: _PetCarousel()),
            const SizedBox(height: 16),
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

class _PetCarousel extends StatefulWidget {
  const _PetCarousel();

  @override
  State<_PetCarousel> createState() => _PetCarouselState();
}

class _PetCarouselState extends State<_PetCarousel> {
  final _store = ProfilePetStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pets = _store.pets;
    if (pets.isEmpty) {
      return const _EmptyPetsCard();
    }
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      children: [
        for (var i = 0; i < pets.length; i++) ...[
          Center(child: _PetCard(pet: pets[i])),
          if (i != pets.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _EmptyPetsCard extends StatelessWidget {
  const _EmptyPetsCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x160B2F25),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pets_rounded,
                size: 40,
                color: Color(0xFF9BB0A8),
              ),
              const SizedBox(height: 8),
              const Text(
                'No pets yet',
                style: TextStyle(
                  color: PetOwnerHomePage.inkColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Add your pet from the profile page',
                style: TextStyle(
                  color: PetOwnerHomePage.mutedTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});

  final ProfilePet pet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Pass the real pet's display profile (with photo + key) so the
          // profile page shows and can update the correct database record.
          Navigator.of(
            context,
          ).pushNamed(PetProfilePage.routeName, arguments: pet.toPetProfile());
        },
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 174,
          height: 168,
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
                PetPhoto(
                  photoUrl: pet.photoUrl,
                  fallbackAsset: PetOwnerHomePage.dogAsset,
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
                    pet.name,
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
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onSeeAll;

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
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(19),
          child: Container(
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
        ),
      ],
    );
  }
}

class _EmptyHomeCard extends StatelessWidget {
  const _EmptyHomeCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B2F25),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFF9BB0A8)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: PetOwnerHomePage.inkColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PetOwnerHomePage.mutedTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(
              backgroundColor: PetOwnerHomePage.inkColor,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OwnerNotificationStore.instance,
      builder: (context, _) {
        final count = OwnerNotificationStore.instance.unreadCount;
        return Material(
          color: Colors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: InkWell(
            key: const ValueKey('owner-notifications-bell'),
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OwnerNotificationsPage(),
              ),
            ),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_rounded,
                    color: PetOwnerHomePage.inkColor,
                    size: 30,
                  ),
                  if (count > 0)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1E17),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class OwnerNotificationsPage extends StatefulWidget {
  const OwnerNotificationsPage({super.key});

  static const String routeName = '/owner-notifications';

  @override
  State<OwnerNotificationsPage> createState() => _OwnerNotificationsPageState();
}

class _OwnerNotificationsPageState extends State<OwnerNotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => OwnerNotificationStore.instance.markAllRead(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFA1FDD8),
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: OwnerNotificationStore.instance,
        builder: (context, _) {
          final items = OwnerNotificationStore.instance.notifications;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 54,
                      color: Color(0xFF60756E),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Clinic updates about your bookings will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF60756E)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            key: const ValueKey('owner-notifications-list'),
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final n = items[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD9E6E1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE6FAF2),
                      child: Icon(
                        Icons.event_note_rounded,
                        color: Color(0xFF147D5B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            n.message,
                            style: const TextStyle(
                              color: Color(0xFF60756E),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

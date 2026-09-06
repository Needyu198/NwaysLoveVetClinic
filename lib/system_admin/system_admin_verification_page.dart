part of 'system_admin_portal.dart';

/// Doctor verification: lists applications, opens an application detail with
/// license/documents/specialty, and Approve/Reject with a confirmation reason.
class AdminVerificationPage extends StatefulWidget {
  const AdminVerificationPage({super.key});

  @override
  State<AdminVerificationPage> createState() => _AdminVerificationPageState();
}

class _AdminVerificationPageState extends State<AdminVerificationPage> {
  bool _pendingOnly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _AdminPageHeader(
            title: 'Doctor Verification',
            subtitle: 'Review and approve applications',
            icon: Icons.verified_user_rounded,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: DoctorVerificationStore.instance,
              builder: (context, _) {
                final all = DoctorVerificationStore.instance.applications;
                final list = _pendingOnly
                    ? all.where((a) => a.status.isPending).toList()
                    : all;
                return ListView(
                  key: const ValueKey('admin-verification-list'),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    Row(
                      children: [
                        _AdminFilterChip(
                          label: 'Pending',
                          selected: _pendingOnly,
                          onTap: () => setState(() => _pendingOnly = true),
                        ),
                        const SizedBox(width: 8),
                        _AdminFilterChip(
                          label: 'All applications',
                          selected: !_pendingOnly,
                          onTap: () => setState(() => _pendingOnly = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (list.isEmpty)
                      const _AdminEmptyState(
                        icon: Icons.verified_rounded,
                        title: 'Nothing to review',
                        message: 'All caught up on verifications.',
                      )
                    else
                      for (final application in list) ...[
                        _AdminApplicationCard(
                          application: application,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminApplicationDetailPage(
                                application: application,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminApplicationCard extends StatelessWidget {
  const _AdminApplicationCard({required this.application, required this.onTap});

  final DoctorApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _adminBorder),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: _adminSoftMint,
              foregroundColor: _adminGreen,
              child: Icon(Icons.medical_services_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    application.specialty,
                    style: const TextStyle(color: _adminMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AdminStatusBadge(
              label: application.status.label,
              color: application.status.color,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Application detail with the professional information and decision buttons.
class AdminApplicationDetailPage extends StatelessWidget {
  const AdminApplicationDetailPage({required this.application, super.key});

  final DoctorApplication application;

  @override
  Widget build(BuildContext context) {
    final licenseExpired = application.licenseExpiry.isBefore(DateTime.now());
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: DoctorVerificationStore.instance,
        builder: (context, _) {
          return Column(
            children: [
              _AdminPageHeader(
                title: application.name,
                subtitle: application.specialty,
                icon: Icons.medical_services_rounded,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    Center(
                      child: _AdminStatusBadge(
                        label: application.status.label,
                        color: application.status.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Contact', style: _adminHeroStyle),
                    const SizedBox(height: 10),
                    _AdminInfoCard(
                      rows: [
                        ('Application', application.id),
                        ('Email', application.email),
                        ('Phone', application.phone),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Professional license', style: _adminHeroStyle),
                    const SizedBox(height: 10),
                    _AdminInfoCard(
                      rows: [
                        ('License', application.licenseNumber),
                        ('Expiry', _shortDay(application.licenseExpiry)),
                        ('Specialty', application.specialty),
                        ('Qualifications', application.qualifications),
                      ],
                    ),
                    if (licenseExpired) ...[
                      const SizedBox(height: 12),
                      _AdminAlertTile(
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFB3261E),
                        title: 'License expired',
                        message:
                            'This license is past its expiry date. Request '
                            'a renewed document before approving.',
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Documents', style: _adminHeroStyle),
                    const SizedBox(height: 10),
                    for (final document in application.documents)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _adminBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_rounded,
                                color: _adminGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(document)),
                              const Icon(
                                Icons.remove_red_eye_outlined,
                                color: _adminMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (application.decisionReason.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _AdminAlertTile(
                        icon: Icons.notes_rounded,
                        color: application.status.color,
                        title: 'Decision reason',
                        message: application.decisionReason,
                      ),
                    ],
                    const SizedBox(height: 22),
                    if (application.status.isPending) ...[
                      FilledButton.icon(
                        key: const ValueKey('admin-approve-doctor'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _adminGreen,
                          minimumSize: const Size.fromHeight(52),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _decide(context, approve: true),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Approve and activate'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB3261E),
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFB3261E)),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _decide(context, approve: false),
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text('Reject application'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _decide(BuildContext context, {required bool approve}) async {
    final reason = await _adminReasonDialog(
      context,
      title: approve
          ? 'Approve ${application.name}?'
          : 'Reject ${application.name}?',
      actionLabel: approve ? 'Approve' : 'Reject',
      actionColor: approve ? _adminGreen : const Color(0xFFB3261E),
    );
    if (reason == null || !context.mounted) return;
    if (approve) {
      DoctorVerificationStore.instance.approve(application, reason);
      _adminNotice(context, '${application.name} approved and activated.');
    } else {
      DoctorVerificationStore.instance.reject(application, reason);
      _adminNotice(context, '${application.name} rejected.');
    }
    Navigator.of(context).pop();
  }
}

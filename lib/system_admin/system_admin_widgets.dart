part of 'system_admin_portal.dart';

class _AdminSimpleHeader extends StatelessWidget {
  const _AdminSimpleHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x28000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// A page-level header with a back button and optional subtitle, used by the
/// admin management sub-pages (Users, Verification, Inventory, Audit).
class _AdminPageHeader extends StatelessWidget {
  const _AdminPageHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(8, 6, 12, 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          if (icon != null) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: _adminSoftMint,
              foregroundColor: _adminGreen,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(color: _adminMuted, fontSize: 13),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

/// A pill-style filter chip matching the clinic's yellow-selected style.
class _AdminFilterChip extends StatelessWidget {
  const _AdminFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF5C518) : _adminMint,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ),
  );
}

/// A small colored status badge.
class _AdminStatusBadge extends StatelessWidget {
  const _AdminStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}

/// Prompts for a required reason string. Returns null if cancelled.
Future<String?> _adminReasonDialog(
  BuildContext context, {
  required String title,
  required String actionLabel,
  Color actionColor = _adminGreen,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _AdminReasonDialog(
      title: title,
      actionLabel: actionLabel,
      actionColor: actionColor,
    ),
  );
}

class _AdminReasonDialog extends StatefulWidget {
  const _AdminReasonDialog({
    required this.title,
    required this.actionLabel,
    required this.actionColor,
  });

  final String title;
  final String actionLabel;
  final Color actionColor;

  @override
  State<_AdminReasonDialog> createState() => _AdminReasonDialogState();
}

class _AdminReasonDialogState extends State<_AdminReasonDialog> {
  final _controller = TextEditingController();
  var _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Record the reason for this action',
            errorText: _error ? 'A reason is required' : null,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: widget.actionColor),
        onPressed: () {
          final text = _controller.text.trim();
          if (text.isEmpty) {
            setState(() => _error = true);
            return;
          }
          Navigator.of(context).pop(text);
        },
        child: Text(widget.actionLabel),
      ),
    ],
  );
}

/// A colored informational tile used for alerts, notes and decision reasons.
class _AdminAlertTile extends StatelessWidget {
  const _AdminAlertTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(message, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: _adminGreen),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _adminMuted),
          ),
        ],
      ),
    ),
  );
}

class _AdminInfoCard extends StatelessWidget {
  const _AdminInfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _adminBorder),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 95,
                child: Text(
                  rows[index].$1,
                  style: const TextStyle(color: _adminMuted),
                ),
              ),
              Expanded(
                child: Text(
                  rows[index].$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (index != rows.length - 1) const Divider(height: 22),
        ],
      ],
    ),
  );
}

part of 'staff_portal.dart';

ClinicPerson? _doctorForName(String name) {
  final target = name.trim().toLowerCase();
  for (final doctor in ClinicDirectory.instance.doctorProfiles) {
    if (doctor.name.trim().toLowerCase() == target) return doctor;
  }
  return null;
}

String _initialFor(String name) {
  final cleaned = name.replaceFirst(RegExp(r'^Dr\.\s*'), '').trim();
  return cleaned.isEmpty ? 'D' : cleaned.characters.first.toUpperCase();
}

/// Consistent avatar for staff and doctors. Public directory/profile photos
/// may be data URIs, web URLs, bundled assets, or local device files.
class _PersonPhoto extends StatelessWidget {
  const _PersonPhoto({
    required this.source,
    required this.fallbackText,
    required this.size,
    super.key,
  });

  final String? source;
  final String fallbackText;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipOval(child: _image() ?? _fallback()),
  );

  Widget? _image() {
    final value = source;
    if (value == null || value.trim().isEmpty) return null;
    if (value.startsWith('data:image/')) {
      try {
        return Image.memory(
          base64Decode(value.substring(value.indexOf(',') + 1)),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _fallback(),
        );
      } catch (_) {
        return null;
      }
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _fallback(),
      );
    }
    if (value.startsWith('assets/')) {
      return Image.asset(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return Image.file(
      File(value),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => ColoredBox(
    color: const Color(0xFFE6FAF2),
    child: Center(
      child: Text(
        fallbackText,
        style: TextStyle(
          color: _green,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _StaffScaffold extends StatelessWidget {
  const _StaffScaffold({
    required this.title,
    required this.child,
    this.onBack,
    this.onLogoTap,
  });
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onLogoTap;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        _InlineHeader(title: title, onBack: onBack, onLogoTap: onLogoTap),
        Expanded(child: child),
      ],
    ),
  );
}

/// Shared mint rounded page header (back arrow + title/subtitle + clinic logo)
/// used across staff subpages so they all match.
class _StaffMintHeader extends StatelessWidget {
  const _StaffMintHeader({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 18, 20),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
            ),
            if (icon != null) ...[
              Icon(icon, size: 24, color: _ink),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: _ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF3B5249),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            Image.asset(
              'assets/photos/logoandphoto/nways_love_logo.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    ),
  );
}

class _InlineHeader extends StatelessWidget {
  const _InlineHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.onLogoTap,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onLogoTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
    child: Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _titleStyle),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
        InkWell(
          key: ValueKey(
            'staff-${title.toLowerCase().replaceAll(' ', '-')}-logo',
          ),
          onTap: onLogoTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: _mint,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/photos/logoandphoto/nways_love_logo.png',
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  rows[i].$1,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ),
              Expanded(
                child: Text(
                  rows[i].$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (i < rows.length - 1) const Divider(height: 22),
        ],
      ],
    ),
  );
}

class _Callout extends StatelessWidget {
  const _Callout({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE6FAF2),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _green),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
      ],
    ),
  );
}

/// A centered empty-state (icon + title + message) shared across staff pages.
class _StaffEmptyState extends StatelessWidget {
  const _StaffEmptyState({
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
          Icon(icon, size: 52, color: _muted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Icon(icon, color: _muted),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: _muted)),
      ],
    ),
  );
}

part of 'staff_portal.dart';

class _StaffScaffold extends StatelessWidget {
  const _StaffScaffold({required this.title, required this.child, this.onBack});
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        _InlineHeader(title: title, onBack: onBack),
        Expanded(child: child),
      ],
    ),
  );
}

class _InlineHeader extends StatelessWidget {
  const _InlineHeader({required this.title, this.subtitle, this.onBack});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
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
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
          child: Image.asset('assets/photos/logoandphoto/nways_love_logo.png'),
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

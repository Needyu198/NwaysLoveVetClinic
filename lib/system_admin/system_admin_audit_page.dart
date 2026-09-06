part of 'system_admin_portal.dart';

/// Read-only audit trail with search and module filters.
class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  final _search = TextEditingController();
  String _module = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _AdminPageHeader(
            title: 'Audit Logs',
            subtitle: 'Read-only record of sensitive actions',
            icon: Icons.receipt_long_rounded,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: AuditLogStore.instance,
              builder: (context, _) {
                final all = AuditLogStore.instance.entries;
                final modules = <String>{
                  'All',
                  ...all.map((e) => e.module),
                }.toList();
                final query = _search.text.trim().toLowerCase();
                final entries = all.where((entry) {
                  if (_module != 'All' && entry.module != _module) {
                    return false;
                  }
                  if (query.isEmpty) return true;
                  return entry.actor.toLowerCase().contains(query) ||
                      entry.action.toLowerCase().contains(query) ||
                      entry.record.toLowerCase().contains(query);
                }).toList();
                return ListView(
                  key: const ValueKey('admin-audit-list'),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search user, action or record ID',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: _adminSoftMint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final module in modules) ...[
                            _AdminFilterChip(
                              label: module,
                              selected: _module == module,
                              onTap: () => setState(() => _module = module),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (entries.isEmpty)
                      const _AdminEmptyState(
                        icon: Icons.history_toggle_off_rounded,
                        title: 'No audit entries',
                        message: 'Matching actions will appear here.',
                      )
                    else
                      for (final entry in entries) ...[
                        _AdminAuditCard(entry: entry),
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

class _AdminAuditCard extends StatelessWidget {
  const _AdminAuditCard({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _adminBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.action,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              _auditTime(entry.timestamp),
              style: const TextStyle(color: _adminMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.module} • ${entry.record}',
          style: const TextStyle(color: _adminMuted, fontSize: 12),
        ),
        if (entry.previousValue.isNotEmpty || entry.newValue.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (entry.previousValue.isNotEmpty)
                _AdminChangePill(
                  label: entry.previousValue,
                  color: const Color(0xFFB3261E),
                ),
              if (entry.previousValue.isNotEmpty && entry.newValue.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _adminMuted,
                  ),
                ),
              if (entry.newValue.isNotEmpty)
                _AdminChangePill(label: entry.newValue, color: _adminGreen),
            ],
          ),
        ],
        if (entry.reason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Reason: ${entry.reason}',
            style: const TextStyle(fontSize: 12.5),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          'By ${entry.actor}',
          style: const TextStyle(color: _adminMuted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _AdminChangePill extends StatelessWidget {
  const _AdminChangePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

String _auditTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _shortDay(time);
}

import 'package:flutter/material.dart';
import 'database_sync.dart';

class DatabaseStatus extends StatelessWidget {
  const DatabaseStatus({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: DatabaseSync.instance,
    builder: (context, _) {
      final sync = DatabaseSync.instance;
      // Only surface the status bar when there is a real sync error the user
      // needs to act on. The routine "Changes saved / Refresh" banner is
      // hidden to keep the top of every page clean.
      final showBar = sync.active && sync.error != null;
      return Column(
        children: [
          if (showBar)
            Material(
              color: const Color(0xFFFFE3DF),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sync.error ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (sync.error != null)
                        TextButton(
                          onPressed: () async {
                            final discard = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reload saved data?'),
                                content: const Text(
                                  'Unsaved changes on this device will be discarded.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Keep changes'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Reload'),
                                  ),
                                ],
                              ),
                            );
                            if (discard == true) {
                              try {
                                await sync.start();
                              } catch (_) {}
                            }
                          },
                          child: const Text('Reload'),
                        ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await sync.refresh();
                          } catch (_) {
                            /* State displays the error. */
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: child),
        ],
      );
    },
  );
}

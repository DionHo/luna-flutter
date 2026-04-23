import 'package:flutter/material.dart';

import '../../../core/models/session.dart';

/// Top navigation bar for session management.
///
/// Shows a dropdown of past sessions, a "New session" button, and a
/// "Delete current session" button.  Also provides a Settings shortcut.
class SessionBar extends StatelessWidget {
  const SessionBar({
    super.key,
    required this.sessions,
    required this.activeSessionId,
    required this.onNewSession,
    required this.onDeleteSession,
    required this.onSessionSelected,
  });

  final List<Session> sessions;
  final int? activeSessionId;
  final VoidCallback onNewSession;
  final VoidCallback onDeleteSession;
  final void Function(int id) onSessionSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // ── Luna label ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Luna',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ),

              // ── Session dropdown ──────────────────────────────────────────
              Expanded(
                child: _SessionDropdown(
                  sessions: sessions,
                  activeSessionId: activeSessionId,
                  onSessionSelected: onSessionSelected,
                ),
              ),

              // ── New session ───────────────────────────────────────────────
              IconButton(
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: 'New session',
                onPressed: onNewSession,
              ),

              // ── Delete session ────────────────────────────────────────────
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete session',
                onPressed: sessions.isEmpty ? null : onDeleteSession,
              ),

              // ── Settings ──────────────────────────────────────────────────
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionDropdown extends StatelessWidget {
  const _SessionDropdown({
    required this.sessions,
    required this.activeSessionId,
    required this.onSessionSelected,
  });

  final List<Session> sessions;
  final int? activeSessionId;
  final void Function(int id) onSessionSelected;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButton<int>(
      value: activeSessionId,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(8),
      items: sessions
          .map(
            (s) => DropdownMenuItem<int>(
              value: s.id,
              child: Text(
                s.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (id) {
        if (id != null) onSessionSelected(id);
      },
    );
  }
}

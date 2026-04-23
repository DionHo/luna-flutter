import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/push_to_talk_button.dart';
import '../widgets/session_bar.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAsync = ref.watch(chatProvider);

    return Scaffold(
      body: chatAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        data: (state) => Column(
          children: [
            // ── Top session bar ─────────────────────────────────────────────
            SessionBar(
              sessions: state.sessions,
              activeSessionId: state.activeSessionId,
              onNewSession: () =>
                  ref.read(chatProvider.notifier).newSession(),
              onDeleteSession: () =>
                  ref.read(chatProvider.notifier).deleteActiveSession(),
              onSessionSelected: (id) =>
                  ref.read(chatProvider.notifier).switchSession(id),
            ),

            // ── Generating indicator ────────────────────────────────────────
            if (state.isGenerating)
              const LinearProgressIndicator(minHeight: 2),

            // ── Chat message list ───────────────────────────────────────────
            Expanded(
              child: state.turns.isEmpty
                  ? _EmptyHint(isListening: state.isListening)
                  : _MessageList(state: state),
            ),

            // ── Push-to-talk button ─────────────────────────────────────────
            PushToTalkButton(
              isListening: state.isListening,
              enabled: !state.isGenerating,
              onPressStart: () => unawaited(
                  ref.read(chatProvider.notifier).startListening()),
              onPressEnd: () => unawaited(
                  ref.read(chatProvider.notifier).stopListening()),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatefulWidget {
  const _MessageList({required this.state});

  final ChatState state;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.turns.length != oldWidget.state.turns.length ||
        widget.state.turns.lastOrNull?.content !=
            oldWidget.state.turns.lastOrNull?.content) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.state.turns.length,
      itemBuilder: (context, index) =>
          MessageBubble(turn: widget.state.turns[index]),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.isListening});

  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isListening ? Icons.mic : Icons.mic_none,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            isListening
                ? 'Listening…'
                : 'Hold the button below to speak',
            style: TextStyle(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}


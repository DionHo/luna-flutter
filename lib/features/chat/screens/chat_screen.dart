import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAsync = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: chatAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (state) => Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.turns.length,
                itemBuilder: (context, index) {
                  return MessageBubble(turn: state.turns[index]);
                },
              ),
            ),
            if (state.isGenerating)
              const LinearProgressIndicator(minHeight: 2),
            InputBar(
              onSubmit: (text) =>
                  ref.read(chatProvider.notifier).sendMessage(text),
              enabled: !state.isGenerating,
            ),
          ],
        ),
      ),
    );
  }
}

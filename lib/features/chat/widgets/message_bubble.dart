import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../core/models/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.turn});

  final ConversationTurn turn;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isUser
            ? Text(turn.content, style: textStyle)
            : GptMarkdown(turn.content, style: textStyle),
      ),
    );
  }
}

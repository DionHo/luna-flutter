import 'package:flutter/material.dart';

/// A large push-to-talk button.
///
/// Hold down to "speak" (STT stub); release to submit.
/// Shows a pulsing mic icon while [isListening] is true.
class PushToTalkButton extends StatelessWidget {
  const PushToTalkButton({
    super.key,
    required this.isListening,
    required this.enabled,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final bool isListening;
  final bool enabled;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: SizedBox(
          width: double.infinity,
          height: 72,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              color: isListening
                  ? colorScheme.error
                  : enabled
                      ? colorScheme.primary
                      : colorScheme.onSurface.withAlpha(30),
              boxShadow: isListening
                  ? [
                      BoxShadow(
                        color: colorScheme.error.withAlpha(80),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(36),
              child: InkWell(
                borderRadius: BorderRadius.circular(36),
                onTapDown: enabled ? (_) => onPressStart() : null,
                onTapUp: enabled && isListening ? (_) => onPressEnd() : null,
                onTapCancel: enabled && isListening ? onPressEnd : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: enabled
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withAlpha(80),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isListening ? 'Release to send' : 'Hold to talk',
                      style: TextStyle(
                        color: enabled
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withAlpha(80),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

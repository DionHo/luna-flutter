import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/message.dart';
import '../../../core/services/conversation_repository.dart';
import '../../../core/services/llm_service.dart';
import '../../../core/services/tts_service.dart';

// ── Service providers ────────────────────────────────────────────────────────

final llmServiceProvider = Provider<LlmService>((ref) {
  final service = LlmService();
  ref.onDispose(service.unloadModel);
  return service;
});

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final repo = ConversationRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

// ── Chat state ───────────────────────────────────────────────────────────────

class ChatState {
  const ChatState({
    this.turns = const [],
    this.isGenerating = false,
  });

  final List<ConversationTurn> turns;
  final bool isGenerating;

  ChatState copyWith({
    List<ConversationTurn>? turns,
    bool? isGenerating,
  }) =>
      ChatState(
        turns: turns ?? this.turns,
        isGenerating: isGenerating ?? this.isGenerating,
      );
}

// ── ChatNotifier ─────────────────────────────────────────────────────────────

class ChatNotifier extends AsyncNotifier<ChatState> {
  @override
  Future<ChatState> build() async {
    final repo = ref.read(conversationRepositoryProvider);
    final history = await repo.loadHistory();
    return ChatState(turns: history);
  }

  /// Sends [userText] through the LLM pipeline and appends the response.
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    final llm = ref.read(llmServiceProvider);
    final tts = ref.read(ttsServiceProvider);
    final repo = ref.read(conversationRepositoryProvider);

    final currentState = state.valueOrNull ?? const ChatState();

    // 1. Append the user turn immediately.
    final userTurn = await repo.addTurn(ConversationTurn(
      id: 0,
      role: 'user',
      content: userText.trim(),
      timestamp: DateTime.now(),
    ));
    state = AsyncData(currentState.copyWith(
      turns: [...currentState.turns, userTurn],
      isGenerating: true,
    ));

    // 2. Stream tokens from the LLM.
    final StringBuffer buffer = StringBuffer();
    try {
      await for (final token in llm.generate(userText.trim())) {
        buffer.write(token);
        // Update the partial assistant turn in state on each token.
        final partialTurn = ConversationTurn(
          id: -1, // temporary id until persisted
          role: 'assistant',
          content: buffer.toString(),
          timestamp: DateTime.now(),
        );
        final prevTurns = (state.valueOrNull ?? const ChatState()).turns;
        final updated = prevTurns.isEmpty || prevTurns.last.id != -1
            ? [...prevTurns, partialTurn]
            : [...prevTurns.sublist(0, prevTurns.length - 1), partialTurn];
        state = AsyncData(
          (state.valueOrNull ?? const ChatState()).copyWith(
            turns: updated,
            isGenerating: true,
          ),
        );
      }
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      return;
    }

    // 3. Persist the completed assistant turn.
    final assistantTurn = await repo.addTurn(ConversationTurn(
      id: 0,
      role: 'assistant',
      content: buffer.toString(),
      timestamp: DateTime.now(),
    ));

    final finalTurns = (state.valueOrNull ?? const ChatState()).turns;
    state = AsyncData(
      (state.valueOrNull ?? const ChatState()).copyWith(
        turns: [
          ...finalTurns.sublist(0, finalTurns.length - 1),
          assistantTurn,
        ],
        isGenerating: false,
      ),
    );

    // 4. Speak the response (fire-and-forget; errors are logged, not fatal).
    try {
      await tts.speak(buffer.toString());
    } on TtsException catch (_) {
      // TTS failure should not interrupt the chat flow.
    }
  }

  Future<void> clearHistory() async {
    final repo = ref.read(conversationRepositoryProvider);
    await repo.clearHistory();
    state = const AsyncData(ChatState());
  }
}

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

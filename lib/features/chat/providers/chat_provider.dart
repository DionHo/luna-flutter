import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/message.dart';
import '../../../core/models/session.dart';
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
    this.sessions = const [],
    this.activeSessionId,
    this.turns = const [],
    this.isGenerating = false,
    this.isListening = false,
  });

  final List<Session> sessions;

  /// The currently displayed session, or null if none exist yet.
  final int? activeSessionId;

  final List<ConversationTurn> turns;
  final bool isGenerating;

  /// True while the push-to-talk button is held (microphone capturing).
  final bool isListening;

  Session? get activeSession {
    if (activeSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == activeSessionId);
    } catch (_) {
      return null;
    }
  }

  ChatState copyWith({
    List<Session>? sessions,
    int? activeSessionId,
    bool clearActiveSession = false,
    List<ConversationTurn>? turns,
    bool? isGenerating,
    bool? isListening,
  }) =>
      ChatState(
        sessions: sessions ?? this.sessions,
        activeSessionId:
            clearActiveSession ? null : (activeSessionId ?? this.activeSessionId),
        turns: turns ?? this.turns,
        isGenerating: isGenerating ?? this.isGenerating,
        isListening: isListening ?? this.isListening,
      );
}

// ── ChatNotifier ─────────────────────────────────────────────────────────────

class ChatNotifier extends AsyncNotifier<ChatState> {
  @override
  Future<ChatState> build() async {
    final repo = ref.read(conversationRepositoryProvider);
    final sessions = await repo.loadSessions();

    if (sessions.isEmpty) {
      // Bootstrap with a first session on a fresh install.
      final first = await repo.createSession('Session 1');
      return ChatState(sessions: [first], activeSessionId: first.id);
    }

    // Most recent session is first in the list.
    final active = sessions.first;
    final turns = await repo.loadTurns(active.id);
    return ChatState(
      sessions: sessions,
      activeSessionId: active.id,
      turns: turns,
    );
  }

  // ── Session actions ────────────────────────────────────────────────────────

  /// Creates a new session and switches to it.
  Future<void> newSession() async {
    final repo = ref.read(conversationRepositoryProvider);
    final current = state.valueOrNull ?? const ChatState();
    final title = 'Session ${current.sessions.length + 1}';
    final session = await repo.createSession(title);
    state = AsyncData(current.copyWith(
      sessions: [session, ...current.sessions],
      activeSessionId: session.id,
      turns: [],
    ));
  }

  /// Switches the active session to [sessionId] and loads its turns.
  Future<void> switchSession(int sessionId) async {
    final current = state.valueOrNull ?? const ChatState();
    if (current.activeSessionId == sessionId) return;

    final repo = ref.read(conversationRepositoryProvider);
    final turns = await repo.loadTurns(sessionId);
    state = AsyncData(current.copyWith(
      activeSessionId: sessionId,
      turns: turns,
    ));
  }

  /// Deletes the active session and switches to the next available one.
  Future<void> deleteActiveSession() async {
    final current = state.valueOrNull ?? const ChatState();
    final sessionId = current.activeSessionId;
    if (sessionId == null) return;

    final repo = ref.read(conversationRepositoryProvider);
    await repo.deleteSession(sessionId);

    final remaining =
        current.sessions.where((s) => s.id != sessionId).toList();

    if (remaining.isEmpty) {
      // Always keep at least one session.
      final fresh = await repo.createSession('Session 1');
      state = AsyncData(ChatState(
        sessions: [fresh],
        activeSessionId: fresh.id,
      ));
      return;
    }

    final nextActive = remaining.first;
    final turns = await repo.loadTurns(nextActive.id);
    state = AsyncData(current.copyWith(
      sessions: remaining,
      activeSessionId: nextActive.id,
      turns: turns,
    ));
  }

  // ── Message actions ───────────────────────────────────────────────────────

  /// Sends [userText] through the LLM pipeline and appends the response.
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    final current = state.valueOrNull ?? const ChatState();
    final sessionId = current.activeSessionId;
    if (sessionId == null) return;

    final llm = ref.read(llmServiceProvider);
    final tts = ref.read(ttsServiceProvider);
    final repo = ref.read(conversationRepositoryProvider);

    // 1. Append the user turn immediately.
    final userTurn = await repo.addTurn(
      sessionId,
      ConversationTurn(
        id: 0,
        role: 'user',
        content: userText.trim(),
        timestamp: DateTime.now(),
      ),
    );
    state = AsyncData(current.copyWith(
      turns: [...current.turns, userTurn],
      isGenerating: true,
    ));

    // 2. If no model is loaded, show a placeholder assistant reply.
    if (!llm.isModelLoaded) {
      final placeholder = await repo.addTurn(
        sessionId,
        ConversationTurn(
          id: 0,
          role: 'assistant',
          content:
              '⚠️ No model loaded. Open Settings to select a GGUF model file.',
          timestamp: DateTime.now(),
        ),
      );
      state = AsyncData((state.valueOrNull ?? const ChatState()).copyWith(
        turns: [
          ...(state.valueOrNull ?? const ChatState()).turns,
          placeholder,
        ],
        isGenerating: false,
      ));
      return;
    }

    // 3. Stream tokens from the LLM.
    final StringBuffer buffer = StringBuffer();
    try {
      await for (final token in llm.generate(userText.trim())) {
        buffer.write(token);
        final partialTurn = ConversationTurn(
          id: -1,
          role: 'assistant',
          content: buffer.toString(),
          timestamp: DateTime.now(),
        );
        final prev = (state.valueOrNull ?? const ChatState()).turns;
        final updated = prev.isEmpty || prev.last.id != -1
            ? [...prev, partialTurn]
            : [...prev.sublist(0, prev.length - 1), partialTurn];
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

    // 4. Persist the completed assistant turn.
    final assistantTurn = await repo.addTurn(
      sessionId,
      ConversationTurn(
        id: 0,
        role: 'assistant',
        content: buffer.toString(),
        timestamp: DateTime.now(),
      ),
    );
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

    // 5. Speak the response (fire-and-forget).
    try {
      await tts.speak(buffer.toString());
    } on TtsException catch (_) {
      // TTS failure does not interrupt the chat flow.
    }
  }

  /// Called when push-to-talk button is pressed down.
  void startListening() {
    final current = state.valueOrNull ?? const ChatState();
    state = AsyncData(current.copyWith(isListening: true));
  }

  /// Called when push-to-talk button is released.
  /// [transcribedText] would come from the STT engine; stubbed for now.
  Future<void> stopListening({String transcribedText = ''}) async {
    final current = state.valueOrNull ?? const ChatState();
    state = AsyncData(current.copyWith(isListening: false));
    if (transcribedText.trim().isNotEmpty) {
      await sendMessage(transcribedText);
    }
  }
}

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);


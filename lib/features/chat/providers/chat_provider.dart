import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/message.dart';
import '../../../core/models/model_config.dart';
import '../../../core/models/session.dart';
import '../../../core/services/audio_recorder_service.dart';
import '../../../core/services/conversation_repository.dart';
import '../../../core/services/llm_service.dart';
import '../../../core/services/model_bootstrap_service.dart';
import '../../../core/services/tts_service.dart';

// ── Service providers ────────────────────────────────────────────────────────

/// Overridden in [main.dart] with a pre-initialised [ModelBootstrapService].
final modelBootstrapProvider = Provider<ModelBootstrapService>(
  (_) => ModelBootstrapService(),
);

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

final audioRecorderProvider = Provider<AudioRecorderService>((ref) {
  final service = AudioRecorderService();
  ref.onDispose(() => service.dispose());
  return service;
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
    // Auto-load the bundled Gemma 4 model if the bootstrap succeeded.
    // Catch ModelLoadException here so a failed load degrades gracefully:
    // the UI still works and shows "⚠️ No model loaded." instead of a
    // full-screen error.  The most common failure mode on Windows is
    // NobodyWho.init() having failed silently (flutter_rust_bridge not
    // initialized), which now results in a clear log message and a usable UI.
    final bootstrap = ref.read(modelBootstrapProvider);
    if (bootstrap.isReady) {
      final llm = ref.read(llmServiceProvider);
      if (!llm.isModelLoaded) {
        try {
          await llm.loadModel(
            ModelConfig(
              modelPath: bootstrap.llmPath,
              projectionModelPath: bootstrap.mmprojPath,
              systemPrompt: 'Answer the question.',
            ),
          );
        } on ModelLoadException catch (e) {
          // Non-fatal: the chat window will show the "no model" placeholder.
          debugPrint('Auto-load failed — running without model: $e');
        }
      }
    }

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
              '⚠️ No model loaded. Place the GGUF model files in data\\flutter_assets\\assets\\models\\ next to luna_flutter.exe.',
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
  /// Starts microphone recording into a temporary WAV file.
  Future<void> startListening() async {
    final recorder = ref.read(audioRecorderProvider);
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      return; // Silently ignore — user will notice the mic never activated.
    }
    await recorder.startRecording();
    final current = state.valueOrNull ?? const ChatState();
    state = AsyncData(current.copyWith(isListening: true));
  }

  /// Called when push-to-talk button is released.
  /// Stops recording and sends the captured audio to the LLM.
  Future<void> stopListening() async {
    final recorder = ref.read(audioRecorderProvider);
    final audioPath = await recorder.stopRecording();
    final current = state.valueOrNull ?? const ChatState();
    state = AsyncData(current.copyWith(isListening: false));
    if (audioPath != null) {
      await _sendAudioMessage(audioPath);
    }
  }

  /// Sends a recorded audio file through the multimodal LLM pipeline and
  /// appends the response to the active session's turn list.
  Future<void> _sendAudioMessage(String audioPath) async {
    final current = state.valueOrNull ?? const ChatState();
    final sessionId = current.activeSessionId;
    if (sessionId == null) return;

    final llm = ref.read(llmServiceProvider);
    final tts = ref.read(ttsServiceProvider);
    final repo = ref.read(conversationRepositoryProvider);

    // 1. Append a user turn that indicates a voice message.
    final userTurn = await repo.addTurn(
      sessionId,
      ConversationTurn(
        id: 0,
        role: 'user',
        content: '🎤 [voice message]',
        timestamp: DateTime.now(),
      ),
    );
    state = AsyncData(current.copyWith(
      turns: [...current.turns, userTurn],
      isGenerating: true,
    ));

    // 2. If no model is loaded, show placeholder.
    if (!llm.isModelLoaded) {
      final placeholder = await repo.addTurn(
        sessionId,
        ConversationTurn(
          id: 0,
          role: 'assistant',
          content:
              '⚠️ No model loaded. Place the GGUF model files in data\\flutter_assets\\assets\\models\\ next to luna_flutter.exe.',
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

    // 3. Stream tokens from the multimodal audio inference.
    final buffer = StringBuffer();
    try {
      await for (final token in llm.generateFromAudio(audioPath)) {
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
}

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);


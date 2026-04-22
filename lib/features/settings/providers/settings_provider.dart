import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.modelPath = '',
    this.voiceId = 'default',
    this.systemPrompt =
        'You are Luna, a helpful and concise voice assistant.',
  });

  final String modelPath;
  final String voiceId;
  final String systemPrompt;

  AppSettings copyWith({
    String? modelPath,
    String? voiceId,
    String? systemPrompt,
  }) =>
      AppSettings(
        modelPath: modelPath ?? this.modelPath,
        voiceId: voiceId ?? this.voiceId,
        systemPrompt: systemPrompt ?? this.systemPrompt,
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _keyModelPath = 'model_path';
  static const _keyVoiceId = 'voice_id';
  static const _keySystemPrompt = 'system_prompt';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      modelPath: prefs.getString(_keyModelPath) ?? '',
      voiceId: prefs.getString(_keyVoiceId) ?? 'default',
      systemPrompt: prefs.getString(_keySystemPrompt) ??
          'You are Luna, a helpful and concise voice assistant.',
    );
  }

  Future<void> setModelPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModelPath, path);
    state = AsyncData((state.valueOrNull ?? const AppSettings())
        .copyWith(modelPath: path));
  }

  Future<void> setVoiceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVoiceId, id);
    state = AsyncData(
        (state.valueOrNull ?? const AppSettings()).copyWith(voiceId: id));
  }

  Future<void> setSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySystemPrompt, prompt);
    state = AsyncData((state.valueOrNull ?? const AppSettings())
        .copyWith(systemPrompt: prompt));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

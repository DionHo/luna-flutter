import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../widgets/model_path_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('LLM Model',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ModelPathPicker(
              currentPath: settings.modelPath,
              onPathSelected: (path) =>
                  ref.read(settingsProvider.notifier).setModelPath(path),
            ),
            const Divider(height: 32),
            const Text('System Prompt',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: settings.systemPrompt,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setSystemPrompt(v),
            ),
          ],
        ),
      ),
    );
  }
}

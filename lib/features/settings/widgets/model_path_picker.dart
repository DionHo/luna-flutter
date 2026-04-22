import 'package:flutter/material.dart';

class ModelPathPicker extends StatelessWidget {
  const ModelPathPicker({
    super.key,
    required this.currentPath,
    required this.onPathSelected,
  });

  final String currentPath;
  final void Function(String path) onPathSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            currentPath.isEmpty ? 'No model selected' : currentPath,
            style: TextStyle(
              color: currentPath.isEmpty
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('Browse'),
          onPressed: () => _pickFile(context),
        ),
      ],
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    // TODO(Phase 1): integrate file_picker package for cross-platform GGUF selection.
    // For now show a text-input dialog as a stub.
    final controller = TextEditingController(text: currentPath);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter model path'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: '/path/to/model.gguf'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('OK')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      onPathSelected(result);
    }
  }
}

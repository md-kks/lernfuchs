import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Lesetext + Multiple-Choice-Fragen-Widget
class ReadingTextWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const ReadingTextWidget({super.key, required this.task, required this.onChanged});

  @override
  State<ReadingTextWidget> createState() => _ReadingTextWidgetState();
}

class _ReadingTextWidgetState extends State<ReadingTextWidget> {
  dynamic _selected;

  String get _text => widget.task.metadata['text'] as String? ?? '';
  List<String> get _choices =>
      (widget.task.metadata['choices'] as List?)?.cast<String>() ?? [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lesetext
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE082), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lies den Text:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE65100),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _text,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Frage (aus task.question — wird außerhalb angezeigt)
        // Multiple Choice Antworten
        ..._choices.map((choice) {
          final isSelected = _selected == choice;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selected = choice);
                widget.onChanged(choice);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withAlpha(80),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.outline.withAlpha(150),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check,
                              size: 14,
                              color: theme.colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        choice,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

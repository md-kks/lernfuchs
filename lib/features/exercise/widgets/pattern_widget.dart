import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Muster-Fortsetzungs-Widget: zeigt sichtbare Elemente + Multiple-Choice-Auswahl
class PatternWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const PatternWidget({super.key, required this.task, required this.onChanged});

  @override
  State<PatternWidget> createState() => _PatternWidgetState();
}

class _PatternWidgetState extends State<PatternWidget> {
  dynamic _selected;

  List<String> get _visible =>
      (widget.task.metadata['visible'] as List?)?.cast<String>() ?? [];

  List<dynamic> get _choices =>
      (widget.task.metadata['choices'] as List?)?.cast<dynamic>() ?? [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Sichtbare Musterelemente
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._visible.map((item) => _MusterElement(label: item)),
              const SizedBox(width: 8),
              // Fragezeichen-Karte
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Antwort-Optionen
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _choices.map((choice) {
            final isSelected = _selected == choice;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = choice);
                widget.onChanged(choice);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withAlpha(80),
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )]
                      : null,
                ),
                child: Center(
                  child: Text(
                    choice.toString(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MusterElement extends StatelessWidget {
  final String label;
  const _MusterElement({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Center(
        child: Text(label, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

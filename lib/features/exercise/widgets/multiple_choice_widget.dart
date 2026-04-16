import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Standard-Multiple-Choice-Widget mit animierten Auswahlkarten.
///
/// Liest die Auswahloptionen aus [TaskModel.metadata]`['choices']`.
/// Unterstützt beliebige Werttypen (String, int, …).
/// Bei Auswahl wird die Karte farbig hervorgehoben (Primary-Color)
/// und [onChanged] mit dem gewählten Wert aufgerufen.
///
/// Genutzt für alle [TaskType.multipleChoice]-Aufgaben ohne spezifisches Widget.
class MultipleChoiceWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const MultipleChoiceWidget({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  dynamic _selected;

  List<dynamic> get _choices =>
      (widget.task.metadata['choices'] as List?)?.cast<dynamic>() ?? [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _choices.map((choice) {
        final isSelected = _selected == choice;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          child: InkWell(
            onTap: () {
              setState(() => _selected = choice);
              widget.onChanged(choice);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Text(
                choice.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

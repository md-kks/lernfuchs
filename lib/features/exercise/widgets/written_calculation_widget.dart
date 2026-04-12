import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/task_model.dart';

/// Schriftliche Rechenverfahren — zeigt die klassische Spaltenform
/// Kinder sehen die Aufgabe strukturiert und geben das Ergebnis ein
class WrittenCalculationWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const WrittenCalculationWidget({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  State<WrittenCalculationWidget> createState() =>
      _WrittenCalculationWidgetState();
}

class _WrittenCalculationWidgetState extends State<WrittenCalculationWidget> {
  final _controller = TextEditingController();

  int get _a => widget.task.metadata['a'] as int? ?? 0;
  int get _b => widget.task.metadata['b'] as int? ?? 0;
  String get _op => widget.task.metadata['op'] as String? ?? '+';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final val = int.tryParse(_controller.text.trim());
      widget.onChanged(val);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aStr = _a.toString();
    final bStr = _b.toString();
    final maxLen = aStr.length > bStr.length ? aStr.length : bStr.length;
    final resultLen = (widget.task.correctAnswer as int).toString().length;
    final displayLen = resultLen > maxLen ? resultLen : maxLen;

    return Column(
      children: [
        // Schriftliche Darstellung
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(60),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _NumberRow(value: aStr, totalLen: displayLen),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _op,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _NumberRow(value: bStr, totalLen: displayLen - 1),
                ],
              ),
              Divider(color: theme.colorScheme.primary, thickness: 2),
              // Eingabezeile
              SizedBox(
                width: displayLen * 24.0 + 16,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: '?',
                    hintStyle: TextStyle(
                      fontSize: 24,
                      color: Colors.grey.shade300,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tipp: Rechne Stelle für Stelle von rechts nach links',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NumberRow extends StatelessWidget {
  final String value;
  final int totalLen;

  const _NumberRow({required this.value, required this.totalLen});

  @override
  Widget build(BuildContext context) {
    return Text(
      value.padLeft(totalLen > 0 ? totalLen : value.length),
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        fontFamily: 'monospace',
        letterSpacing: 4,
      ),
    );
  }
}

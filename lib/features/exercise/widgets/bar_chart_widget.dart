import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Animiertes Balkendiagramm für [DiagramReadingTemplate] (topic: `diagramme`, Kl.4).
///
/// Liest Kategorien und Werte aus [TaskModel.metadata]`['labels']`/`['values']`.
/// Balken wachsen beim ersten Render animiert von unten nach oben.
/// Darunter erscheinen Multiple-Choice-Antworten — typische Fragen:
/// maximaler Wert, Summe aller Werte, Differenz zwischen max und min.
class BarChartWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const BarChartWidget({super.key, required this.task, required this.onChanged});

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  dynamic _selected;
  final _controller = TextEditingController();

  List<String> get _categories =>
      (widget.task.metadata['categories'] as List?)?.cast<String>() ?? [];
  List<int> get _values =>
      (widget.task.metadata['values'] as List?)?.cast<int>() ?? [];
  String get _title => widget.task.metadata['title'] as String? ?? '';
  String get _qType => widget.task.metadata['qType'] as String? ?? 'sum';
  List<dynamic> get _choices =>
      (widget.task.metadata['choices'] as List?)?.cast<dynamic>() ?? [];

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
    final maxVal = _values.isEmpty ? 1 : _values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Diagramm-Titel
        Text(
          _title,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Balkendiagramm
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_categories.length, (i) {
              final value = i < _values.length ? _values[i] : 0;
              final heightRatio = maxVal > 0 ? value / maxVal : 0.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300 + i * 50),
                    width: 36,
                    height: (140 * heightRatio).clamp(4, 140),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(
                          150 + (i * 20).clamp(0, 100)),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 48,
                    child: Text(
                      _categories[i],
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        // Antwort-Bereich
        if (_qType == 'max') ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
                  child: Text(
                    choice.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          SizedBox(
            width: 140,
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: '?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

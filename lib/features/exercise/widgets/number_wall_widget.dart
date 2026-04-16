import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/task_model.dart';

/// Zahlenmauer-Widget für [NumberWallTemplate] (topic: `zahlenmauern`, Kl.1/2).
///
/// Zeigt eine 3-stöckige Pyramide (Basis: 3 Felder, Mitte: 2, Spitze: 1).
/// Invariante: jede Zahl ist die Summe der beiden darunter liegenden.
/// Genau ein Feld ist leer — das Kind tippt den fehlenden Wert ein.
/// Liest [metadata] `['a']`, `['b']`, `['c']`, `['missingPos']`.
class NumberWallWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const NumberWallWidget({super.key, required this.task, required this.onChanged});

  @override
  State<NumberWallWidget> createState() => _NumberWallWidgetState();
}

class _NumberWallWidgetState extends State<NumberWallWidget> {
  final _controller = TextEditingController();

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

  Map<String, dynamic> get _md => widget.task.metadata;
  String get _hidden => _md['hidden'] as String? ?? '';

  int? _val(String key) {
    if (key == _hidden) return null;
    return _md[key] as int?;
  }

  @override
  Widget build(BuildContext context) {
    // Mauer: 3 Reihen
    // Reihe 3 (oben): top
    // Reihe 2: mid1, mid2
    // Reihe 1 (unten): a, b, c
    return Column(
      children: [
        const Text(
          'Jeder Stein = Summe der zwei darunter',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        _WallRow(cells: [_val('top')], hidden: _hidden == 'top',
            controller: _controller, onChange: widget.onChanged),
        const SizedBox(height: 4),
        _WallRow(cells: [_val('mid1'), _val('mid2')],
            hidden: _hidden == 'mid1' || _hidden == 'mid2',
            hiddenIndex: _hidden == 'mid1' ? 0 : (_hidden == 'mid2' ? 1 : -1),
            controller: _controller, onChange: widget.onChanged),
        const SizedBox(height: 4),
        _WallRow(cells: [_val('a'), _val('b'), _val('c')],
            hidden: ['a', 'b', 'c'].contains(_hidden),
            hiddenIndex: _hidden == 'a' ? 0 : (_hidden == 'b' ? 1 : (_hidden == 'c' ? 2 : -1)),
            controller: _controller, onChange: widget.onChanged),
      ],
    );
  }
}

class _WallRow extends StatelessWidget {
  final List<int?> cells;
  final bool hidden;
  final int hiddenIndex;
  final TextEditingController controller;
  final ValueChanged<dynamic> onChange;

  const _WallRow({
    required this.cells,
    required this.hidden,
    this.hiddenIndex = -1,
    required this.controller,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: cells.asMap().entries.map((e) {
        final isHidden = hidden && hiddenIndex == e.key;
        final value = e.value;
        if (isHidden) {
          return _InputCell(controller: controller);
        }
        return _NumberCell(value: value ?? 0);
      }).toList(),
    );
  }
}

class _NumberCell extends StatelessWidget {
  final int value;
  const _NumberCell({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 68,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      child: Center(
        child: Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _InputCell extends StatelessWidget {
  final TextEditingController controller;
  const _InputCell({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 68,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          hintText: '?',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
      ),
    );
  }
}

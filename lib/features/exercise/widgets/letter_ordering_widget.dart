import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Buchstaben-Salat-Widget für Anagramm-Aufgaben.
///
/// Zeigt gemischte Buchstaben-Chips ([metadata]`['letters']`) in zufälliger
/// Anordnung. Das Kind tippt Buchstaben der Reihe nach an — sie wandern
/// in die Ziel-Zeile. Getippte Buchstaben können durch erneuten Tap
/// wieder entfernt werden.
///
/// Meldet die aktuelle Reihenfolge als `List<String>` via [onChanged].
/// Genutzt von [AnagramTemplate] (topic: `buchstaben_salat`, Kl.1).
class LetterOrderingWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const LetterOrderingWidget({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  State<LetterOrderingWidget> createState() => _LetterOrderingWidgetState();
}

class _LetterOrderingWidgetState extends State<LetterOrderingWidget> {
  late List<String> _available; // noch nicht gewählte Buchstaben
  final List<String> _chosen = []; // bereits gewählte Reihenfolge

  @override
  void initState() {
    super.initState();
    _available = (widget.task.metadata['letters'] as List?)
            ?.cast<String>()
            .toList() ??
        [];
  }

  void _pick(int idx) {
    setState(() {
      _chosen.add(_available.removeAt(idx));
    });
    widget.onChanged(_chosen);
  }

  void _unpick(int idx) {
    setState(() {
      _available.add(_chosen.removeAt(idx));
    });
    widget.onChanged(_chosen.isEmpty ? null : _chosen);
  }

  void _reset() {
    setState(() {
      _available.addAll(_chosen);
      _chosen.clear();
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Gewählte Buchstaben (oben)
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(80),
              width: 2,
            ),
          ),
          child: _chosen.isEmpty
              ? Center(
                  child: Text(
                    'Tippe auf Buchstaben →',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _chosen.asMap().entries.map((e) {
                    return GestureDetector(
                      onTap: () => _unpick(e.key),
                      child: _LetterChip(
                        letter: e.value,
                        color: theme.colorScheme.primary,
                        textColor: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 8),

        // Pfeil-Indikator
        Icon(
          Icons.arrow_upward_rounded,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),

        // Verfügbare Buchstaben (unten)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _available.asMap().entries.map((e) {
            return GestureDetector(
              onTap: () => _pick(e.key),
              child: _LetterChip(
                letter: e.value,
                color: Colors.white,
                textColor: theme.colorScheme.onSurface,
                borderColor: theme.colorScheme.outline.withAlpha(80),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Reset
        if (_chosen.isNotEmpty)
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Zurücksetzen'),
          ),
      ],
    );
  }
}

class _LetterChip extends StatelessWidget {
  final String letter;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  const _LetterChip({
    required this.letter,
    required this.color,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

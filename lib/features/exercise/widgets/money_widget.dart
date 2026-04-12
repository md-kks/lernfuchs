import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Geld-zählen-Widget für [MoneyTemplate] (topic: `geld`, Kl.2).
///
/// Zeigt eine zufällige Münzkombination (1/2/5/10/20/50 Cent, 1/2 Euro)
/// mit visueller Farbkodierung (Gold/Silber/Bronze-Töne).
/// Das Kind tippt den Gesamtbetrag in Euro (z.B. `"0,75"` oder `"1.50"`) ein.
/// Dezimaltrenner Komma und Punkt werden beide akzeptiert.
class MoneyWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const MoneyWidget({super.key, required this.task, required this.onChanged});

  @override
  State<MoneyWidget> createState() => _MoneyWidgetState();
}

class _MoneyWidgetState extends State<MoneyWidget> {
  final _controller = TextEditingController();

  List<int> get _coins =>
      (widget.task.metadata['coins'] as List?)?.cast<int>() ?? [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        widget.onChanged(null);
        return;
      }
      // Akzeptiere "1,50" oder "150" (Cent)
      final normalized = text.replaceAll(',', '.');
      final euros = double.tryParse(normalized);
      if (euros != null) {
        widget.onChanged((euros * 100).round());
      } else {
        final cents = int.tryParse(text);
        widget.onChanged(cents);
      }
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

    return Column(
      children: [
        // Münzen-Anzeige
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _coins.map((coin) => _CoinWidget(valueInCent: coin)).toList(),
        ),
        const SizedBox(height: 24),
        // Hinweis
        Text(
          'Eingabe: z.B. "1,50" für 1,50 € oder "75" für 75 Cent',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Eingabefeld
        SizedBox(
          width: 200,
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: '?.??',
              suffixText: '€',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoinWidget extends StatelessWidget {
  final int valueInCent;
  const _CoinWidget({required this.valueInCent});

  String get _label {
    if (valueInCent >= 100) {
      return '${valueInCent ~/ 100} €';
    }
    return '$valueInCent¢';
  }

  Color get _color {
    if (valueInCent >= 100) return const Color(0xFFFFD700); // Gold
    if (valueInCent >= 10) return const Color(0xFFC0C0C0);  // Silber
    return const Color(0xFFCD7F32);                          // Bronze
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color,
        border: Border.all(color: _color.withAlpha(200), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

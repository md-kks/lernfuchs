import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Zeigt eine Punktmenge visuell an — Kind gibt die Anzahl ein
class DotCountWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const DotCountWidget({super.key, required this.task, required this.onChanged});

  @override
  State<DotCountWidget> createState() => _DotCountWidgetState();
}

class _DotCountWidgetState extends State<DotCountWidget> {
  final _controller = TextEditingController();

  int get _dotCount => widget.task.metadata['dotCount'] as int? ?? 0;

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
    final cols = 5;
    final rows = (_dotCount / cols).ceil();

    return Column(
      children: [
        // Punkte-Anzeige
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
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(_dotCount, (i) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 100 + i * 30),
                curve: Curves.bounceOut,
                builder: (_, scale, __) => Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        // Eingabefeld
        SizedBox(
          width: 120,
          child: TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: '?',
              hintStyle: TextStyle(
                fontSize: 32,
                color: Colors.grey.shade300,
                fontWeight: FontWeight.w800,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 3),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

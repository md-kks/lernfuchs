import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/task_model.dart';
import '../../../shared/constants/app_text_styles.dart';

/// Universelles Freitext-/Zahlen-Eingabefeld.
///
/// Erkennt automatisch, ob [TaskModel.correctAnswer] eine Zahl oder ein String
/// ist und schaltet entsprechend die Tastatur und Input-Formatierung:
/// - Zahl → Numpad, nur Ziffern erlaubt
/// - Text → Standard-Tastatur, beliebige Zeichen
///
/// Genutzt als Fallback-Widget für alle [TaskType.freeInput]-Aufgaben sowie
/// für [TaskType.interactive] ohne spezifisches Widget.
class FreeInputWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const FreeInputWidget({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  State<FreeInputWidget> createState() => _FreeInputWidgetState();
}

class _FreeInputWidgetState extends State<FreeInputWidget> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        widget.onChanged(null);
      } else {
        final num = int.tryParse(text);
        widget.onChanged(num ?? text);
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
    final isNumber = widget.task.correctAnswer is int ||
        widget.task.correctAnswer is double;

    return TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      textAlign: TextAlign.center,
      style: AppTextStyles.taskAnswer,
      decoration: InputDecoration(
        hintText: '?',
        hintStyle: AppTextStyles.taskAnswer.copyWith(
          color: Colors.grey.shade300,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}

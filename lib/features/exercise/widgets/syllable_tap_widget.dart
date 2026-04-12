import 'package:flutter/material.dart';
import '../../../core/models/task_model.dart';

/// Silben-Klatsch-Widget für [TaskType.tapRhythm].
///
/// Das Kind tippt für jede Silbe eines Wortes einmal auf den großen Button.
/// Der Button pulst bei jedem Tipp animiert (ScaleTransition). Darunter
/// erscheinen nummerierte Chip-Buttons (1–4) zur direkten Auswahl.
/// Aktuelle Tipp-Anzahl wird groß angezeigt und via [onChanged] gemeldet.
///
/// Genutzt von [SyllableCountTemplate] (topic: `silben`, Kl.1).
class SyllableTapWidget extends StatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const SyllableTapWidget({super.key, required this.task, required this.onChanged});

  @override
  State<SyllableTapWidget> createState() => _SyllableTapWidgetState();
}

class _SyllableTapWidgetState extends State<SyllableTapWidget>
    with SingleTickerProviderStateMixin {
  int _taps = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  String get _word => widget.task.metadata['word'] as String? ?? '';
  String get _split => widget.task.metadata['syllableSplit'] as String? ?? _word;
  List<int> get _choices =>
      (widget.task.metadata['choices'] as List?)?.cast<int>() ?? [1, 2, 3, 4];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnim = Tween(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() => _taps++);
    _pulseController.forward(from: 0.0);
    widget.onChanged(_taps);
  }

  void _reset() {
    setState(() => _taps = 0);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Silbentrennung anzeigen
        Text(
          _split,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tippe für jede Silbe einmal!',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),

        // Tap-Button mit Puls-Animation
        GestureDetector(
          onTap: _onTap,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: _pulseController.isAnimating ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(80),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_taps',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Klatschen',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Reset
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Zurücksetzen'),
        ),

        const SizedBox(height: 16),

        // Alternative: direkt tippen (Multiple Choice)
        const Text('Oder wähle direkt:'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _choices.map((count) {
            final isSelected = _taps == count;
            return GestureDetector(
              onTap: () {
                setState(() => _taps = count);
                widget.onChanged(count);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 52,
                height: 52,
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
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : null,
                    ),
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

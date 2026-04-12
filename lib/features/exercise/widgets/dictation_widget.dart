import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task_model.dart';
import '../../../core/services/providers.dart';

/// Diktat-Widget: Wort kurz anzeigen (oder per TTS vorlesen) → Kind schreibt.
///
/// ### TTS-Modus (wenn aktiviert)
/// - Das Wort wird beim Widget-Aufbau via [TtsService] vorgelesen.
/// - Ein "Nochmal vorlesen"-Button ermöglicht wiederholtes Vorlesen.
/// - Die visuelle Anzeige des Wortes entfällt — echtes Diktat-Erlebnis.
///
/// ### Fallback (TTS deaktiviert)
/// - Wort wird 3 Sekunden angezeigt, dann automatisch versteckt.
/// - "Nochmal anzeigen"-Button für zusätzliche Hilfe.
///
/// Genutzt von [DictationTemplate] (topic: `diktat`, Kl.3).
class DictationWidget extends ConsumerStatefulWidget {
  final TaskModel task;
  final ValueChanged<dynamic> onChanged;

  const DictationWidget(
      {super.key, required this.task, required this.onChanged});

  @override
  ConsumerState<DictationWidget> createState() => _DictationWidgetState();
}

class _DictationWidgetState extends ConsumerState<DictationWidget> {
  bool _wordVisible = true;
  final _controller = TextEditingController();

  String get _word => widget.task.metadata['word'] as String? ?? '';

  @override
  void initState() {
    super.initState();

    final tts = ref.read(ttsServiceProvider);
    if (tts.isEnabled) {
      // TTS-Modus: Wort sofort vorlesen, nicht anzeigen
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _wordVisible = false);
          tts.speak(_word);
        }
      });
    } else {
      // Fallback: Wort 3 Sekunden anzeigen, dann verstecken
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _wordVisible = false);
      });
    }

    _controller.addListener(() {
      final text = _controller.text.trim();
      widget.onChanged(text.isEmpty ? null : text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _repeatWord() {
    final tts = ref.read(ttsServiceProvider);
    if (tts.isEnabled) {
      tts.speak(_word);
    } else {
      setState(() => _wordVisible = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _wordVisible = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tts = ref.watch(ttsServiceProvider);
    final isTtsMode = tts.isEnabled;

    return Column(
      children: [
        // Wort-Anzeige / TTS-Status
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _wordVisible && !isTtsMode
                ? theme.colorScheme.primary.withAlpha(20)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _wordVisible && !isTtsMode
                  ? theme.colorScheme.primary
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: isTtsMode
              // TTS-Modus: Lautsprecher-Icon + Wiederholen-Button
              ? Column(
                  children: [
                    Icon(Icons.volume_up_rounded,
                        color: theme.colorScheme.primary, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Das Wort wurde vorgelesen — schreibe es auf!',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _repeatWord,
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Nochmal vorlesen'),
                    ),
                  ],
                )
              : _wordVisible
                  // Visuell-Modus: Wort anzeigen
                  ? Column(
                      children: [
                        Text(
                          _word,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Merke dir das Wort! Es verschwindet gleich…',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    )
                  // Visuell-Modus: Wort versteckt
                  : Column(
                      children: [
                        const Icon(Icons.visibility_off_rounded,
                            color: Colors.grey, size: 32),
                        const SizedBox(height: 8),
                        const Text('Das Wort ist versteckt — schreibe es auf!'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _repeatWord,
                          child: const Text('Nochmal anzeigen'),
                        ),
                      ],
                    ),
        ),
        const SizedBox(height: 20),

        // Eingabefeld
        TextField(
          controller: _controller,
          autofocus: false,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.sentences,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Schreibe hier…',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 3),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }
}

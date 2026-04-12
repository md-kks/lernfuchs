import 'package:flutter/material.dart';

import '../../shared/constants/app_colors.dart';
import 'dialogue_definition.dart';

class DialogueOverlay extends StatefulWidget {
  final DialogueLibrary library;
  final DialogueScene scene;
  final VoidCallback onFinished;
  final VoidCallback onClose;

  const DialogueOverlay({
    super.key,
    required this.library,
    required this.scene,
    required this.onFinished,
    required this.onClose,
  });

  @override
  State<DialogueOverlay> createState() => _DialogueOverlayState();
}

class _DialogueOverlayState extends State<DialogueOverlay> {
  int _lineIndex = 0;

  DialogueLine get _line => widget.scene.lines[_lineIndex];

  bool get _isLastLine => _lineIndex >= widget.scene.lines.length - 1;

  void _continue() {
    if (_isLastLine) {
      widget.onFinished();
      return;
    }
    setState(() => _lineIndex++);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scene.lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final character = widget.library.character(_line.speakerId);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _CharacterPortrait(character: character),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                character?.name ?? _line.speakerId,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (widget.scene.title.isNotEmpty)
                                Text(
                                  widget.scene.title,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Schließen',
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _line.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _continue,
                        child: Text(_isLastLine ? 'Weiter' : 'Weiter'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterPortrait extends StatelessWidget {
  final DialogueCharacter? character;

  const _CharacterPortrait({required this.character});

  @override
  Widget build(BuildContext context) {
    final character = this.character;
    final portraitAsset = character?.portraitAsset ?? '';
    if (portraitAsset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          portraitAsset,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(24),
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        character?.portraitFallback.isNotEmpty == true
            ? character!.portraitFallback
            : '?',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

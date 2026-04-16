import 'package:flutter/material.dart';

import '../../shared/constants/app_colors.dart';
import 'dialogue_definition.dart';
import 'hint_definition.dart';

class LearningHintPanel extends StatefulWidget {
  final HintSetDefinition hintSet;
  final DialogueLibrary dialogueLibrary;

  const LearningHintPanel({
    super.key,
    required this.hintSet,
    required this.dialogueLibrary,
  });

  @override
  State<LearningHintPanel> createState() => _LearningHintPanelState();
}

class _LearningHintPanelState extends State<LearningHintPanel> {
  int _revealedLevel = 0;

  @override
  Widget build(BuildContext context) {
    final character = widget.dialogueLibrary.character(
      widget.hintSet.mentorCharacterId,
    );
    final visibleHint = widget.hintSet.hintForLevel(_revealedLevel);
    final hasMore = _revealedLevel < widget.hintSet.levels.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(18),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MentorPortrait(character: character),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    character == null
                        ? 'Hinweis'
                        : 'Tipp von ${character.name}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: hasMore
                      ? () => setState(() => _revealedLevel++)
                      : null,
                  child: Text(hasMore ? 'Tipp anzeigen' : 'Alle Tipps offen'),
                ),
              ],
            ),
            if (visibleHint != null) ...[
              const SizedBox(height: 8),
              Text(
                visibleHint.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(visibleHint.text),
            ],
          ],
        ),
      ),
    );
  }
}

class _MentorPortrait extends StatelessWidget {
  final DialogueCharacter? character;

  const _MentorPortrait({required this.character});

  @override
  Widget build(BuildContext context) {
    final portraitAsset = character?.portraitAsset ?? '';
    if (portraitAsset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          portraitAsset,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        character?.portraitFallback.isNotEmpty == true
            ? character!.portraitFallback
            : '?',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

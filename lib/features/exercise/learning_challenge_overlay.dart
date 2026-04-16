import 'package:flutter/material.dart';
import '../../core/learning/learning.dart';
import '../../game/dialogue/dialogue_definition.dart';
import '../../game/dialogue/hint_definition.dart';
import '../../game/dialogue/learning_hint_panel.dart';
import 'learning_challenge_session.dart';
import 'learning_session_mode.dart';

class LearningChallengeOverlay extends StatelessWidget {
  final String title;
  final LearningRequest request;
  final LearningSessionMode mode;
  final String? message;
  final DialogueLibrary? dialogueLibrary;
  final HintSetDefinition? hintSet;
  final ValueChanged<LearningChallengeResult> onCompleted;
  final VoidCallback onClose;

  const LearningChallengeOverlay({
    super.key,
    required this.title,
    required this.request,
    required this.mode,
    this.message,
    this.dialogueLibrary,
    this.hintSet,
    required this.onCompleted,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Schließen',
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (message != null) ...[
                      Text(message!),
                      const SizedBox(height: 12),
                    ],
                    if (hintSet != null && dialogueLibrary != null) ...[
                      LearningHintPanel(
                        hintSet: hintSet!,
                        dialogueLibrary: dialogueLibrary!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 500,
                      child: LearningChallengeSession(
                        request: request,
                        mode: mode,
                        showScaffold: false,
                        onCompleted: onCompleted,
                        onCancel: onClose,
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

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game/quest/quest_definition.dart';
import '../../shared/constants/app_text_styles.dart';

class QuestRewardOverlay extends StatefulWidget {
  final List<QuestRewardDefinition> rewards;
  final VoidCallback onDismiss;

  const QuestRewardOverlay({
    super.key,
    required this.rewards,
    required this.onDismiss,
  });

  @override
  State<QuestRewardOverlay> createState() => _QuestRewardOverlayState();
}

class _QuestRewardOverlayState extends State<QuestRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final scale = Curves.elasticOut.transform(t.clamp(0.0, 0.6) / 0.6);
            final opacity = (t.clamp(0.0, 0.2) / 0.2);

            return Opacity(
              opacity: opacity,
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Belohnung!',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: widget.rewards.map((reward) {
                          return _RewardCard(reward: reward);
                        }).toList(),
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'Tippe zum Fortfahren',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final QuestRewardDefinition reward;

  const _RewardCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2108),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8F00), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RewardIcon(type: reward.type),
          const SizedBox(height: 12),
          Text(
            '${reward.amount}x ${reward.title}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8D5B0),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardIcon extends StatelessWidget {
  final String type;

  const _RewardIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
      ),
      child: Center(
        child: Text(
          _emojiForType(type),
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  String _emojiForType(String type) {
    switch (type) {
      case 'collectible':
        return '✨';
      case 'upgradeUnlock':
        return '🔨';
      default:
        return '🎁';
    }
  }
}

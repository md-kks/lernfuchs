import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/providers.dart';
import 'baumhaus_painter.dart';

class BaumhausScreen extends ConsumerStatefulWidget {
  const BaumhausScreen({super.key});

  @override
  ConsumerState<BaumhausScreen> createState() => _BaumhausScreenState();
}

class _BaumhausScreenState extends ConsumerState<BaumhausScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final stage = storage.getIntValue('baumhaus_stage', defaultValue: 0);
    final items = storage.getStringListValue('baumhaus_items');
    final finoStyle = ref.watch(finoEvolutionProvider).style;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              CustomPaint(
                painter: BaumhausPainter(
                  baumhausStage: stage,
                  items: items,
                  finoStyle: finoStyle,
                  breathT: _controller.value,
                ),
                child: const SizedBox.expand(),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _BackButton(onTap: () => Navigator.pop(context)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xCC3E2108),
            border: Border.all(color: const Color(0xFFFF8F00), width: 1.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFF8F00)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/progress.dart';
import '../../core/services/providers.dart';

class ParentOnboardingScreen extends ConsumerStatefulWidget {
  const ParentOnboardingScreen({super.key});

  @override
  ConsumerState<ParentOnboardingScreen> createState() =>
      _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState
    extends ConsumerState<ParentOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final PageController _pageController;
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _slideIndex = 0;
  int _grade = 1;
  bool _showSetup = false;
  DateTime? _birthdate;

  static const _slides = [
    _ParentSlide(
      title: 'Was ist LernFuchs?',
      body:
          'Fino löst Waldabenteuer - und lernt dabei ganz von selbst. Kein stumpfes Wiederholen, kein Druck. Nur echtes Abenteuer.',
      tts:
          'Hallo! Ich bin Ova. Ich passe auf Fino auf - und auf dein Kind.',
      visual: _SlideVisual.friends,
    ),
    _ParentSlide(
      title: 'Wie lernt mein Kind hier?',
      body:
          'LernFuchs merkt was geübt werden muss und wählt passende Aufgaben. Alles ohne dass dein Kind es merkt.',
      tts:
          'Das System beobachtet was dein Kind kann - und passt sich automatisch an.',
      visual: _SlideVisual.graph,
    ),
    _ParentSlide(
      title: 'Dein Elternbereich',
      body:
          'Mit einem PIN geschützt. Du siehst Fortschritt, stellst Spielzeit ein und wählst Lernthemen. Keine Werbung, kein Tracking.',
      tts:
          'Im Elternbereich siehst du alles und kannst die Spielzeit begrenzen.',
      visual: _SlideVisual.pin,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakSlide());
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speakSlide() async {
    await ref.read(ttsServiceProvider).speak(_slides[_slideIndex].tts);
  }

  void _next() {
    if (_slideIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    } else {
      setState(() => _showSetup = true);
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 7, now.month, now.day),
      firstDate: DateTime(now.year - 12),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _finishSetup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final pin = _pinController.text;
    final storage = ref.read(storageServiceProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    await storage.setOnboardingValue('parent_pin', pin);
    if (_birthdate != null) {
      await storage.setOnboardingValue(
        'child_birthdate',
        _birthdate!.toIso8601String().substring(0, 10),
      );
    }

    final activeId = ref.read(appSettingsProvider).activeProfileId;
    final existing = storage.getProfile(activeId);
    await storage.saveProfile(
      ChildProfile(
        id: activeId,
        name: existing?.name ?? 'Fino',
        grade: _grade,
        avatarEmoji: existing?.avatarEmoji ?? 'Fino',
        totalStars: existing?.totalStars ?? 0,
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );
    await settingsNotifier.setParentPin(pin);
    if (!mounted) return;
    context.go('/onboarding/child');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              CustomPaint(
                painter: _ParentOnboardingPainter(t: _controller.value),
                child: const SizedBox.expand(),
              ),
              SafeArea(
                child: _showSetup ? _buildSetup(context) : _buildSlides(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlides() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() => _slideIndex = index);
              _speakSlide();
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 46, 22, 20),
                child: Column(
                  children: [
                    const Spacer(),
                    _WoodPanel(title: slide.title, body: slide.body),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 96,
                      child: CustomPaint(
                        painter: _SlideVisualPainter(slide.visual),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: index == _slideIndex
                          ? const Color(0xFFFF8F00)
                          : Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _StoneButton(
                text: _slideIndex == _slides.length - 1
                    ? 'Einrichten'
                    : 'Weiter',
                onTap: _next,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetup(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF3E2108),
              border: Border.all(color: const Color(0xFFFF8F00), width: 1.5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elternbereich einrichten',
                  style: TextStyle(
                    color: Color(0xFFFF8F00),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Wähle einen PIN für den Elternbereich',
                  style: TextStyle(color: Color(0xFFE8D5B0)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    filled: true,
                    labelText: 'PIN eingeben',
                  ),
                  validator: (value) =>
                      value != null && value.length == 4
                          ? null
                          : 'Bitte 4 Ziffern eingeben.',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    filled: true,
                    labelText: 'PIN bestätigen',
                  ),
                  validator: (value) =>
                      value == _pinController.text
                          ? null
                          : 'Die PINs stimmen nicht überein.',
                ),
                const SizedBox(height: 18),
                const Text(
                  'In welcher Klasse ist dein Kind?',
                  style: TextStyle(color: Color(0xFFE8D5B0)),
                ),
                Wrap(
                  spacing: 4,
                  children: [1, 2, 3, 4]
                      .map(
                        (grade) => ChoiceChip(
                          label: Text('Klasse $grade'),
                          selected: _grade == grade,
                          onSelected: (_) => setState(() => _grade = grade),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Geburtstag (optional, für Überraschungen)',
                  style: TextStyle(color: Color(0xFFE8D5B0)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _pickBirthdate,
                  child: Text(
                    _birthdate == null
                        ? 'Geburtstag auswählen'
                        : _birthdate!.toIso8601String().substring(0, 10),
                  ),
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.center,
                  child: _StoneButton(text: 'Los gehts!', onTap: _finishSetup),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentSlide {
  final String title;
  final String body;
  final String tts;
  final _SlideVisual visual;

  const _ParentSlide({
    required this.title,
    required this.body,
    required this.tts,
    required this.visual,
  });
}

enum _SlideVisual { friends, graph, pin }

class _ParentOnboardingPainter extends CustomPainter {
  final double t;

  const _ParentOnboardingPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2D4A2D), Color(0xFF4A7A4A)],
    ).createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;
    paint.color = const Color(0xFF1A2E1A);
    for (var i = 0; i < 7; i++) {
      final x = size.width * (i / 6);
      final h = size.height * (0.24 + (i % 3) * 0.04);
      final path = Path()
        ..moveTo(x - 42, size.height * 0.78)
        ..lineTo(x, size.height * 0.78 - h)
        ..lineTo(x + 42, size.height * 0.78)
        ..close();
      canvas.drawPath(path, paint);
    }
    paint.color = const Color(0xFF1E1200);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      paint,
    );
    _drawOva(
      canvas,
      Offset(size.width / 2, size.height * 0.72 + 4 * (t < 0.5 ? t : 1 - t)),
      size.width < 420 ? 1.1 : 1.25,
    );
  }

  void _drawOva(Canvas canvas, Offset c, double scale) {
    final paint = Paint()..color = const Color(0xFFFFB74D);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 34 * scale, height: 42 * scale),
      paint,
    );
    paint.color = const Color(0xFFFFE0B2);
    canvas.drawCircle(c.translate(0, -10 * scale), 15 * scale, paint);
    paint.color = const Color(0xFF5D4037);
    canvas.drawCircle(c.translate(-5 * scale, -12 * scale), 2 * scale, paint);
    canvas.drawCircle(c.translate(5 * scale, -12 * scale), 2 * scale, paint);
    final wing = Paint()..color = const Color(0xFFFFCC80);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-20 * scale, 0),
        width: 18 * scale,
        height: 30 * scale,
      ),
      wing,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(20 * scale, 0),
        width: 18 * scale,
        height: 30 * scale,
      ),
      wing,
    );
  }

  @override
  bool shouldRepaint(covariant _ParentOnboardingPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _SlideVisualPainter extends CustomPainter {
  final _SlideVisual visual;

  const _SlideVisualPainter(this.visual);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFF8F00);
    if (visual == _SlideVisual.graph) {
      paint.style = PaintingStyle.fill;
      for (var i = 0; i < 5; i++) {
        final h = 18.0 + i * 12;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(36 + i * 34, size.height - h - 18, 22, h),
            const Radius.circular(4),
          ),
          paint,
        );
      }
      _label(canvas, 'Automatisch angepasst', Offset(size.width / 2, 8));
      return;
    }
    if (visual == _SlideVisual.pin) {
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 88,
        height: 62,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
      _label(canvas, 'PIN', rect.center.translate(0, -8));
      return;
    }
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFEF6C00);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.58), 20, paint);
    paint.color = const Color(0xFF8D6E63);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.58), 24, paint);
  }

  void _label(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFF8F00),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant _SlideVisualPainter oldDelegate) =>
      oldDelegate.visual != visual;
}

class _WoodPanel extends StatelessWidget {
  final String title;
  final String body;

  const _WoodPanel({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF3E2108),
        border: Border.all(color: const Color(0xFFFF8F00), width: 1.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFF8F00),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFFE8D5B0),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoneButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _StoneButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            border: Border.all(color: const Color(0xFF1B5E20), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE8F5E9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

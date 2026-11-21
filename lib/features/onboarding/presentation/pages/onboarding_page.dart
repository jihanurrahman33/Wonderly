import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/features/onboarding/presentation/widgets/onboarding_art.dart';

class _Slide {
  const _Slide({
    required this.background,
    required this.title,
    required this.body,
    required this.art,
  });

  final Color background;
  final String title;
  final String body;
  final Widget art;
}

final _slides = [
  const _Slide(
    background: AppColors.sage,
    title: 'Learn by playing',
    body:
        'Short quizzes, shapes and puzzles. One question at a time, '
        'so every lesson stays fun.',
    art: PlayArt(),
  ),
  const _Slide(
    background: AppColors.butter,
    title: 'Collect stars and badges',
    body:
        'Every right answer earns a star. Fill the bar to unlock new '
        'badges and topics.',
    art: StarsArt(),
  ),
  const _Slide(
    background: AppColors.sky,
    title: 'Grown-ups stay in the loop',
    body:
        'A protected parent zone shows progress and lets you set a daily '
        'play limit.',
    art: GrownUpsArt(),
  ),
];

/// Three-step welcome tour shown before profile setup.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.go(Routes.profileSetup);

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                  child: Text('Skip', style: AppText.label(16)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              const SizedBox(height: 16),
              _Dots(count: _slides.length, index: _page),
              const SizedBox(height: 20),
              WonderButton(
                label: _isLast ? 'Get started' : 'Next',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: slide.background,
              borderRadius: BorderRadius.circular(40),
            ),
            clipBehavior: Clip.antiAlias,
            child: FittedBox(
              child: SizedBox(width: 350, height: 350, child: slide.art),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  slide.title,
                  style: AppText.heading(30),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  slide.body,
                  style: AppText.body(
                    17,
                    weight: FontWeight.w600,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == index ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i == index ? AppColors.ink : AppColors.sand,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

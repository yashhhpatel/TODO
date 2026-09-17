import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/player_service.dart';
import '../../widgets/common.dart';

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page(this.icon, this.title, this.body);
}

const _pages = [
  _Page(Icons.grid_view_rounded, 'Find Hidden Words',
      'Words are hidden inside the letter grid. Your job is to find them all.'),
  _Page(Icons.swipe_rounded, 'Swipe or Tap',
      'Drag your finger across letters to select a word — or tap the first and last letter.'),
  _Page(Icons.explore_rounded, 'Any Direction',
      'Words can run across, down, diagonally, and even backwards. Keep your eyes open!'),
  _Page(Icons.monetization_on_rounded, 'Earn Coins',
      'Complete levels to earn coins and stars. Solve fast for bigger bonuses.'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _index = 0;

  void _finish() => context.read<PlayerService>().completeOnboarding();

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip',
                    style: TextStyle(color: AppColors.grey500)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(34),
                          ),
                          child: Icon(p.icon, size: 62, color: AppColors.ink),
                        ),
                        const SizedBox(height: 36),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: AppTheme.number(26)),
                        const SizedBox(height: 14),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.grey700,
                              fontSize: 15,
                              height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final on = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: on ? AppColors.ink : AppColors.grey300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: isLast ? 'Get Started' : 'Next',
                icon: isLast ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                onTap: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _pc.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

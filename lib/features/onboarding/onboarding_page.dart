// lib/features/onboarding/onboarding_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/select_role_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_index + 1) % 3;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const kBlue = Colors.lightBlue; // aapka same blue

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;

            final logoH = (maxH * 0.22).clamp(120.0, 200.0);
            final topSpacing = (maxH * 0.02).clamp(8.0, 24.0);

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: maxH * 0.36,
                    top: topSpacing,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: logoH,
                            maxWidth: maxW * 0.7,
                          ),
                          child: Image.asset(
                            'assets/images/app logo-1.jpg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: maxH * 0.02),
                      AspectRatio(
                        aspectRatio: 1.05,
                        child: PageView(
                          controller: _controller,
                          onPageChanged: (i) => setState(() => _index = i),
                          children: const [
                            _Slide(
                              icon: Icons.home_work_rounded,
                              title: 'Reliable PGs at Your Fingertips!',
                              subtitle:
                              'Find verified stays, compare prices,\nbook a visit — anytime, anywhere.',
                            ),
                            _Slide(
                              icon: Icons.verified_user_rounded,
                              title: 'Verified Listings & Amenities',
                              subtitle:
                              'Photos, pricing & amenities —\nall transparent and up to date.',
                            ),
                            _Slide(
                              icon: Icons.support_agent_rounded,
                              title: 'Quick Visit & Easy Booking',
                              subtitle:
                              'Schedule a visit or reserve your bed\nin just a few taps.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: _BottomSheet(
                    index: _index,
                    blue: kBlue,
                    onNext: () {
                      if (_index < 2) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SelectRolePage(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final circleSize = (size.width * 0.55).clamp(180.0, 280.0);
    final iconSize = (circleSize * 0.38).clamp(72.0, 108.0);

    return Center(
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: Colors.lightBlue.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, size: iconSize, color: Colors.lightBlue),
        ),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final int index;
  final VoidCallback onNext;
  final Color blue;
  const _BottomSheet({
    required this.index,
    required this.onNext,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: blue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _titles[index],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitles[index],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  backgroundColor: Colors.white,
                  foregroundColor: blue,
                ),
                onPressed: onNext,
                child: Text(
                  index < 2 ? 'Next' : 'Continue',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _titles = [
  'Reliable PGs at Your Fingertips!',
  'Verified Listings & Amenities',
  'Quick Visit',
];

const _subtitles = [
  'Find verified stays, compare prices,\nbook a visit — anytime, anywhere.',
  'Photos, pricing & amenities —\nall transparent and up to date.',
  'Schedule a visit or reserve your bed\nin just a few taps.',
];

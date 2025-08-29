// lib/main.dart
import 'package:flutter/material.dart';
import 'features/onboarding/onboarding_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StayEasyPG());
}

class StayEasyPG extends StatelessWidget {
  const StayEasyPG({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      scrollBehavior: const _NoGlowScrollBehavior(),

      builder: (context, child) {
        final mq = MediaQuery.of(context);

        final clampedScaler = mq.textScaler
            .clamp(minScaleFactor: 0.90, maxScaleFactor: 1.10);

        return MediaQuery(
          data: mq.copyWith(
            textScaler: clampedScaler,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF22C1A0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C1A0),
          primary: const Color(0xFF22C1A0),
          secondary: const Color(0xFF159D7E),
        ),
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.standard,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),

      home: const OnboardingPage(),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {

    return child;
  }
}

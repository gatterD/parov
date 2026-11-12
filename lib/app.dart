import 'package:flutter/material.dart';

import 'screens/simulation_screen.dart';
import 'theme/app_theme.dart';

class SteamHeatingApp extends StatelessWidget {
  const SteamHeatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SimulationScreen(),
    );
  }
}

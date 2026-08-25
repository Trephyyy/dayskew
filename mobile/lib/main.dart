import 'package:flutter/material.dart';

import 'src/screens/home_screen.dart';
import 'src/state/app_controller.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const DaySkewApp());
}

class DaySkewApp extends StatefulWidget {
  const DaySkewApp({super.key});

  @override
  State<DaySkewApp> createState() => _DaySkewAppState();
}

class _DaySkewAppState extends State<DaySkewApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
  }

  @override
  void dispose() {
    _controller.api.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DaySkew',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => HomeScreen(controller: _controller),
      ),
    );
  }
}
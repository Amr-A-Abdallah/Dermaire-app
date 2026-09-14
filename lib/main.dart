import 'package:flutter/material.dart';

import 'dermaire_state.dart';
import 'dermaire_theme.dart';
import 'onboarding_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DermaireApp());
}

class DermaireApp extends StatefulWidget {
  const DermaireApp({super.key});

  @override
  State<DermaireApp> createState() => _DermaireAppState();
}

class _DermaireAppState extends State<DermaireApp> {
  late final DermaireState state = DermaireState();

  @override
  void initState() {
    super.initState();
    state.loadPreferences();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => MaterialApp(
      title: 'Dermaire',
      debugShowCheckedModeBanner: false,
      theme: DermaireTheme.light,
      darkTheme: DermaireTheme.dark,
      themeMode: state.themeMode,
      home: WelcomeScreen(state: state),
    ),
  );
}

class MyApp extends DermaireApp {
  const MyApp({super.key});
}

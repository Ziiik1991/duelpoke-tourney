import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/welcome_screen.dart';
import 'constants/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

/// Widget raíz de la aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Crea la instancia única del TournamentProvider que gestionará los datos.
      create: (context) => TournamentProvider(),
      // MaterialApp configura aspectos básicos de la app (tema, pantalla inicial).
      child: MaterialApp(
        title: 'DuelPoke Tourney',
        theme: AppTheme.darkTheme,
        home: const WelcomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

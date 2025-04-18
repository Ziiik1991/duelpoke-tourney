import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/welcome_screen.dart';
import 'constants/app_theme.dart'; // Importa el tema
// Importa el AudioManager

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para algunas inicializaciones
  // Opcional: Inicializar AudioManager aquí si es necesario antes de runApp
  // AudioManager.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos ChangeNotifierProvider para que TournamentProvider esté disponible en toda la app
    return ChangeNotifierProvider(
      create: (context) => TournamentProvider(),
      child: MaterialApp(
        title: 'DuelPoke Tourney',
        theme: AppTheme.darkTheme, // Aplicar el tema oscuro personalizado
        home: const WelcomeScreen(), // La pantalla inicial
        debugShowCheckedModeBanner: false, // Opcional: quitar banner de debug
      ),
    );
  }
}
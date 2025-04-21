import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart'; // Asegúrate que la ruta es correcta
import 'screens/welcome_screen.dart';     // Asegúrate que la ruta es correcta
import 'constants/app_theme.dart';       // Asegúrate que la ruta es correcta

// Función principal que inicia la aplicación Flutter.
void main() {
  // Asegura que los bindings de Flutter estén inicializados antes de runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Corre la aplicación principal definida en MyApp
  runApp(const MyApp());
}

/// Widget raíz de la aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Envuelve la app con ChangeNotifierProvider para manejar el estado del torneo.
    return ChangeNotifierProvider(
      // Crea la instancia única del TournamentProvider que gestionará los datos.
      create: (context) => TournamentProvider(),
      // MaterialApp configura aspectos básicos de la app (tema, pantalla inicial).
      child: MaterialApp(
        title: 'DuelPoke Tourney', // Título de la app (visible en tareas recientes, etc.)
        theme: AppTheme.darkTheme, // Aplicar el tema oscuro definido en app_theme.dart
        home: const WelcomeScreen(), // La pantalla que se muestra al iniciar la app
        debugShowCheckedModeBanner: false, // Oculta la cinta "DEBUG" en la esquina
      ),
    );
  }
}
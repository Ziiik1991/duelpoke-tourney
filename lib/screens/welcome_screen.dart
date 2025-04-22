import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemNavigator
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tournament_provider.dart';
import 'register_participants_screen.dart';
import '../services/audio_manager.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb; // Para kDebugMode y kIsWeb

/// Pantalla de bienvenida inicial de la aplicación.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar el gestor de audio al cargar la pantalla
    AudioManager.instance.init();
  }

  @override
  void dispose() {
    super.dispose();
    // No es necesario llamar a AudioManager.instance.dispose() aquí generalmente
  }

  /// Reproduce el sonido de clic estándar.
  void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener referencia al provider (sin escuchar cambios aquí)
    final tournamentProvider = Provider.of<TournamentProvider>(
      context,
      listen: false,
    );
    // Calcular dimensiones relativas a la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.4; // Ancho de botón (40%)
    const double buttonFontSize = 20.0; // Tamaño de fuente para botones

    if (kDebugMode) print("Building WelcomeScreen");

    return Scaffold(
      body: Container(
        // Imagen de fondo
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_welcome.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            // Permite scroll si el contenido excede la altura
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 50.0,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centrar verticalmente
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Centrar horizontalmente
              children: <Widget>[
                // Logo de la aplicación
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  // Widget a mostrar si el logo no carga
                  errorBuilder:
                      (c, e, s) => const Icon(
                        Icons.shield_outlined,
                        size: 100,
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 60), // Espacio vertical
                // Botón "Nuevo Torneo"
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: const Text('Nuevo Torneo'),
                    style: ElevatedButton.styleFrom(
                      // Estilo personalizado de fuente
                      textStyle: GoogleFonts.lato(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (kDebugMode) print("Nuevo Torneo button pressed");
                      _playClickSound();
                      AudioManager.instance
                          .stopBackgroundMusic(); // Parar música anterior
                      tournamentProvider
                          .resetTournament(); // Reiniciar datos del torneo
                      AudioManager.instance
                          .playBackgroundMusic(); // Iniciar música nueva
                      // Navegar a la pantalla de registro
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const RegisterParticipantsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20), // Espacio entre botones
                // Botón "Salir"
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Salir'),
                    style: ElevatedButton.styleFrom(
                      // Estilo personalizado (color y fuente)
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.lato(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (kDebugMode) print("Salir button pressed");
                      _playClickSound();
                      // Salir de la app (solo funciona en móvil/escritorio)
                      if (!kIsWeb) {
                        if (kDebugMode)
                          print("Attempting SystemNavigator.pop()");
                        SystemNavigator.pop();
                      } else {
                        // En web, mostrar mensaje
                        if (kDebugMode)
                          print("Cannot pop on web, showing SnackBar.");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Cierra la pestaña del navegador para salir.",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

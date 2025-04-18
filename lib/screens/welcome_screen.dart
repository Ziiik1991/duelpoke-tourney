import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemNavigator.pop()
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import 'register_participants_screen.dart';
import '../services/audio_manager.dart'; // Para sonidos
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es web

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

// --- CLASE STATE ACTUALIZADA ---
class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  void initState() {
    super.initState();
    // Asegurarse que AudioManager esté inicializado
    AudioManager.instance.init();
    // ---> LÍNEA COMENTADA/ELIMINADA <---
    // Ya NO iniciamos la música aquí automáticamente
    // AudioManager.instance.playBackgroundMusic();
  }

  @override
  void dispose() {
    // Si la música se inicia con el botón, quizás no necesites detenerla aquí,
    // o quizás sí, dependiendo de si quieres que pare al volver a WelcomeScreen.
    // Por ahora la dejamos comentada.
    // AudioManager.instance.stopBackgroundMusic();
    super.dispose();
  }

  void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos listen: false aquí porque solo usamos el provider para acciones
    final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        // --- Fondo ---
        decoration: const BoxDecoration(
          image: DecorationImage(
             image: AssetImage('assets/images/background_welcome.png'), // Asegúrate que exista
             fit: BoxFit.cover,
             // Placeholder si no tienes imagen:
             // image: NetworkImage('https://via.placeholder.com/600x1000/1A237E/FFFFFF?text=Welcome+Background'),
             // fit: BoxFit.cover,
          ),
        ),
        // --- Contenido Centrado ---
        child: Center(
          child: SingleChildScrollView(
             padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- Logo ---
                 Image.asset(
                   'assets/images/logo.png', // Asegúrate que exista
                   height: 120,
                   errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield_outlined, size: 100, color: Colors.white70),
                   // Placeholder si no tienes imagen:
                   // Image.network('https://via.placeholder.com/400x150/FFFFFF/000000?text=DuelPoke+Tourney+Logo', height: 100),
                ),
                const SizedBox(height: 60),

                // --- Botón Nuevo Torneo ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Nuevo Torneo'),
                  // --- onPressed ACTUALIZADO ---
                  onPressed: () {
                    // Tocar sonido de clic
                    _playClickSound();

                    // ---> INICIAR MÚSICA DE FONDO AQUÍ <---
                    AudioManager.instance.playBackgroundMusic();

                    // Resetear torneo y navegar
                    tournamentProvider.resetTournament();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterParticipantsScreen()),
                    );
                  },
                  // --- FIN de onPressed ACTUALIZADO ---
                ),
                const SizedBox(height: 20),

                // --- Botones Continuar y Opciones (sin cambios) ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('Continuar Torneo'),
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700]?.withOpacity(0.5),
                    foregroundColor: Colors.grey[400]
                  ),
                ),
                 const SizedBox(height: 20),
                 ElevatedButton.icon(
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Opciones'),
                   onPressed: null,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.grey[700]?.withOpacity(0.5),
                    foregroundColor: Colors.grey[400]
                   ),
                 ),
                const SizedBox(height: 40),

                // --- Botón Salir (sin cambios) ---
                 ElevatedButton.icon(
                   icon: const Icon(Icons.exit_to_app),
                   label: const Text('Salir'),
                  onPressed: () {
                     _playClickSound();
                      if (!kIsWeb) {
                         SystemNavigator.pop();
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cierra la pestaña del navegador para salir."))
                         );
                      }
                  },
                   style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
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
// --- FIN DE LA CLASE STATE ACTUALIZADA ---
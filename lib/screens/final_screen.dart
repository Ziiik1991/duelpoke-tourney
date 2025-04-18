import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'welcome_screen.dart'; // Para volver al inicio
import 'package:google_fonts/google_fonts.dart'; // Para fuentes especiales

class FinalScreen extends StatefulWidget {
  const FinalScreen({super.key});

  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Configurar animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Duración de la animación
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut, // Efecto rebote
    );

     _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn), // Aparece después de un delay
    );


    // Iniciar la animación después de construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _animationController.forward();
       // Sonido de victoria ya se tocó al navegar aquí desde TournamentScreen
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

   void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  void _startNewTournament() {
     _playClickSound();
     // Resetear el torneo en el provider
     context.read<TournamentProvider>().resetTournament();
     // Navegar a Welcome Screen eliminando las anteriores
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
  }


  @override
  Widget build(BuildContext context) {
    // Obtener el ganador del provider (usar watch para reconstruir si cambia)
    final winner = context.watch<TournamentProvider>().winner;

    return Scaffold(
      body: Container(
        // --- Fondo (REEMPLAZA con imagen de victoria o color) ---
         decoration: BoxDecoration(
           gradient: LinearGradient( // Un gradiente como ejemplo
             colors: [Colors.indigo[900]!, Colors.purple[900]!],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
           ),
          // image: DecorationImage(
          //    image: AssetImage('assets/images/background_final.png'), // <-- REEMPLAZA ESTO
          //   fit: BoxFit.cover,
          // ),
        ),
        child: Center(
          child: SingleChildScrollView( // Para pantallas pequeñas
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(
                    Icons.emoji_events, // Icono de trofeo
                    size: 150.0,
                    color: Colors.amberAccent, // Color dorado
                     shadows: [ // Sombra para destacar
                        Shadow(
                            color: Colors.black54,
                            blurRadius: 10.0,
                            offset: Offset(4, 4),
                        )
                     ],
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    '¡Felicidades!',
                    style: GoogleFonts.pressStart2p( // Fuente pixelada
                      fontSize: 28,
                      color: Colors.white,
                      shadows: [
                         const Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(2, 2))
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                 FadeTransition(
                   opacity: _fadeAnimation,
                   child: Text(
                     winner?.name ?? 'Al Campeón', // Mostrar nombre del ganador
                      style: GoogleFonts.lato( // Fuente más legible para el nombre
                       fontSize: 32,
                       fontWeight: FontWeight.bold,
                       color: Colors.white,
                       shadows: [
                         const Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(2, 2))
                       ],
                     ),
                     textAlign: TextAlign.center,
                   ),
                 ),
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Jugar Nuevo Torneo'),
                     style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        backgroundColor: Colors.amberAccent, // Botón destacado
                        foregroundColor: Colors.black,
                        textStyle: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)
                     ),
                    onPressed: _startNewTournament,
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

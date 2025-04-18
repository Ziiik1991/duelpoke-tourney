// En lib/screens/tournament_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../widgets/match_widget.dart';
import '../models/match.dart'; // Importar Match
import '../services/audio_manager.dart'; // Para sonidos
import 'welcome_screen.dart'; // Para reiniciar
import 'final_screen.dart'; // Para navegar al final
import 'package:flutter/foundation.dart'; // Para kDebugMode

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

// --- CLASE STATE ACTUALIZADA ---
class _TournamentScreenState extends State<TournamentScreen> {
  final TransformationController _transformationController = TransformationController();
  // Variable para guardar la referencia al provider
  TournamentProvider? _tournamentProviderRef;

  @override
  void initState() {
    super.initState();
    // Guarda la referencia al provider aquí:
    _tournamentProviderRef = context.read<TournamentProvider>();

    // Añadir listener después de que el primer frame se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usar la referencia guardada o leerla de nuevo
      final provider = _tournamentProviderRef; // O context.read<TournamentProvider>();
      if (provider != null && mounted) { // Chequeo mounted
        provider.addListener(_checkIfTournamentFinished);
      }
    });
  }

  @override
  void dispose() {
    // Usa la referencia guardada para quitar el listener
    if (_tournamentProviderRef != null) {
      try {
         _tournamentProviderRef!.removeListener(_checkIfTournamentFinished);
      } catch (e) {
          if (kDebugMode) print("Handled error removing listener in dispose (likely hot reload): $e");
      }
    }
    _transformationController.dispose();
    super.dispose();
  }

  // Método actualizado para chequear fin y detener música
  void _checkIfTournamentFinished() {
      // Siempre chequear 'mounted' primero
      if (!mounted) return;

      // Usar la referencia guardada
      final provider = _tournamentProviderRef;
      if (provider == null) return; // Chequeo de seguridad

      if (provider.isTournamentFinished) {
          // Remover listener ANTES de navegar
          try {
             provider.removeListener(_checkIfTournamentFinished);
          } catch (e) {
              if (kDebugMode) print("Handled error removing listener before navigation: $e");
          }

          // --- >>> DETENER MÚSICA DE FONDO <<< ---
          AudioManager.instance.stopBackgroundMusic();

          // Tocar sonido de victoria del torneo
          AudioManager.instance.playWinTournamentSound();

          // Chequear 'mounted' OTRA VEZ antes de la navegación
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FinalScreen()),
            );
          }
      }
  }


  void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  void _resetTournament() {
    _playClickSound();
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        // ... (contenido del diálogo sin cambios) ...
         return AlertDialog(
              title: const Text('Confirmar Reseteo'),
              content: const Text('¿Estás seguro de que quieres reiniciar el torneo? Se perderá todo el progreso.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                     _playClickSound();
                    Navigator.of(ctx).pop(); // Cerrar diálogo
                  },
                ),
                TextButton(
                  child: const Text('Reiniciar', style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                     _playClickSound();
                     Navigator.of(ctx).pop(); // Cerrar diálogo
                     // Usar la referencia guardada o context.read si prefieres
                     _tournamentProviderRef?.resetTournament(); // O context.read<TournamentProvider>().resetTournament();
                     // Volver a la pantalla de bienvenida
                     Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                        (Route<dynamic> route) => false, // Eliminar todas las rutas anteriores
                     );
                  },
                ),
              ],
            );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Usar un Consumer aquí para obtener el provider y escuchar cambios
    return Consumer<TournamentProvider>(
        builder: (context, provider, child) {
           // ... (lógica inicial del build sin cambios significativos,
           // asegurar que usa 'provider' del builder o 'context.watch') ...
           if (!provider.isTournamentActive && !provider.isTournamentFinished) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                  if(mounted) { try { Navigator.of(context).pop(); } catch (e) {} }
               });
               return const Scaffold(body: Center(child: Text("Error: Torneo no activo.")));
           }
           if (provider.isTournamentFinished) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
           }

      return Scaffold(
        appBar: AppBar(
          title: Text('Torneo (${provider.participantCount} Jugadores)'), // Usa provider del builder
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reiniciar Torneo',
              onPressed: _resetTournament,
            ),
          ],
           leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                 // ... (lógica del diálogo de salir sin cambios) ...
                  _playClickSound();
                  showDialog(
                      context: context,
                      builder: (BuildContext ctx) => AlertDialog(
                          title: const Text("Salir del Torneo"),
                          content: const Text("¿Seguro que quieres salir? El progreso actual se perderá."),
                          actions: [
                              TextButton(onPressed: (){ _playClickSound(); Navigator.of(ctx).pop(); }, child: const Text("Cancelar")),
                              TextButton(
                                  onPressed: () {
                                      _playClickSound();
                                      Navigator.of(ctx).pop(); // Cierra dialogo
                                      context.read<TournamentProvider>().resetTournament(); // Usa context.read aquí está bien
                                      Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                          (route) => false);
                                  },
                                  child: const Text("Salir", style: TextStyle(color: Colors.redAccent)),
                              )
                          ],
                      ),
                  );
              },
           ),
        ),
        body: InteractiveViewer(
           // ... (resto del InteractiveViewer y llamada a _buildBracketLayout sin cambios) ...
           transformationController: _transformationController,
           minScale: 0.2,
           maxScale: 4.0,
           constrained: false,
           boundaryMargin: const EdgeInsets.all(50.0),
           child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: _buildBracketLayout(context, provider.rounds, provider.participantCount), // Usa provider del builder
             ),
           ),
           floatingActionButton: FloatingActionButton(
             mini: true,
             tooltip: 'Centrar Vista',
             onPressed: () => _transformationController.value = Matrix4.identity(),
             child: const Icon(Icons.center_focus_strong),
           ),
        );
      }
    );
  }

  // --- Función para construir el Layout del Bracket ---
  Widget _buildBracketLayout(BuildContext context, List<List<Match>> rounds, int participantCount) {
    // ... (lógica de _buildBracketLayout y los layouts específicos sin cambios) ...
    if (rounds.isEmpty) {
       return const Center(child: Text("Generando bracket..."));
     }
     switch (participantCount) {
       case 2: return _buildLayoutFor2(rounds);
       case 4: return _buildLayoutFor4(rounds);
       case 8: return _buildLayoutFor8(context, rounds); // Pasamos context
       case 16: return _buildLayoutFor16(rounds);
       default: return Center(child: Text("Número de participantes ($participantCount) no soportado para visualización.", textAlign: TextAlign.center));
     }
  }

   // --- Layouts Específicos ---
   // (Código de _buildLayoutFor2, _buildLayoutFor4, _buildLayoutFor8, _buildLayoutFor16 sin cambios)
    Widget _buildLayoutFor2(List<List<Match>> rounds) {
     if (rounds.isEmpty || rounds[0].isEmpty) return const SizedBox.shrink();
     return Center(child: MatchWidget(match: rounds[0][0], widgetWidth: 200, nameFontSize: 14));
    }
    Widget _buildLayoutFor4(List<List<Match>> rounds) {
     if (rounds.length < 2 || rounds[0].isEmpty || rounds[1].isEmpty) return const SizedBox.shrink();
     final semiFinals = rounds[0];
     final finalMatch = rounds[1][0];
     return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MatchWidget(match: semiFinals[0]),
          const SizedBox(width: 50),
          MatchWidget(match: finalMatch, widgetWidth: 180, nameFontSize: 14),
           const SizedBox(width: 50),
           MatchWidget(match: semiFinals[1]),
        ],
     );
    }
    Widget _buildLayoutFor8(BuildContext context, List<List<Match>> rounds) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.grey[800]?.withOpacity(0.7),
          child: Text(
            "Layout para 8 participantes\n¡PENDIENTE!",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.orangeAccent, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    Widget _buildLayoutFor16(List<List<Match>> rounds) {
      if (rounds.length < 4) return const SizedBox.shrink();
      final roundOf16 = rounds[0];
      final quarterFinals = rounds[1];
      final semiFinals = rounds[2];
      final finalMatch = rounds[3][0];
      Widget buildRoundColumn(List<Match> matches, {double spacing = 30.0}) {
        List<Widget> columnChildren = [];
        for (int i = 0; i < matches.length; i++) {
            columnChildren.add(MatchWidget(match: matches[i]));
            if (i < matches.length - 1) {
                columnChildren.add(SizedBox(height: spacing));
            }
        }
        return Column( mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: columnChildren,);
      }
      List<Match> getMatchesForSide(List<Match> roundMatches, bool isLeftSide) {
        int half = (roundMatches.length / 2).ceil();
        return isLeftSide ? roundMatches.sublist(0, half) : roundMatches.sublist(half);
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildRoundColumn(getMatchesForSide(roundOf16, true), spacing: 20),
          const SizedBox(width: 40),
          buildRoundColumn(getMatchesForSide(quarterFinals, true), spacing: 80),
          const SizedBox(width: 40),
          buildRoundColumn(getMatchesForSide(semiFinals, true), spacing: 180),
          const SizedBox(width: 60),
          MatchWidget(match: finalMatch, widgetWidth: 180, nameFontSize: 16),
          const SizedBox(width: 60),
          buildRoundColumn(getMatchesForSide(semiFinals, false), spacing: 180),
          const SizedBox(width: 40),
          buildRoundColumn(getMatchesForSide(quarterFinals, false), spacing: 80),
          const SizedBox(width: 40),
          buildRoundColumn(getMatchesForSide(roundOf16, false), spacing: 20),
        ],
      );
    }
}
// --- FIN DE LA CLASE STATE ACTUALIZADA ---
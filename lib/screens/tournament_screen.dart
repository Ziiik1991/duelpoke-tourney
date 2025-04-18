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

class _TournamentScreenState extends State<TournamentScreen> {
  final TransformationController _transformationController = TransformationController();
  TournamentProvider? _tournamentProviderRef;

  @override
  void initState() {
    super.initState();
    _tournamentProviderRef = context.read<TournamentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = _tournamentProviderRef;
      if (provider != null && mounted) {
        provider.addListener(_checkIfTournamentFinished);
      }
    });
  }

  @override
  void dispose() {
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

  void _checkIfTournamentFinished() {
      if (!mounted) return;
      final provider = _tournamentProviderRef;
      if (provider == null) return;

      if (provider.isTournamentFinished) {
          try {
             provider.removeListener(_checkIfTournamentFinished);
          } catch (e) {
              if (kDebugMode) print("Handled error removing listener before navigation: $e");
          }
          AudioManager.instance.stopBackgroundMusic(); // Detener música de fondo
          AudioManager.instance.playWinTournamentSound(); // Tocar sonido de victoria
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
         return AlertDialog(
              title: const Text('Confirmar Reseteo'),
              content: const Text('¿Estás seguro de que quieres reiniciar el torneo? Se perderá todo el progreso.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                     _playClickSound();
                    Navigator.of(ctx).pop();
                  },
                ),
                TextButton(
                  child: const Text('Reiniciar', style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                     _playClickSound();
                     Navigator.of(ctx).pop();
                     _tournamentProviderRef?.resetTournament();
                     Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                        (Route<dynamic> route) => false,
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
    return Consumer<TournamentProvider>(
        builder: (context, provider, child) {
           if (!provider.isTournamentActive && !provider.isTournamentFinished) {
               WidgetsBinding.instance.addPostFrameCallback((_) {
                  if(mounted) { try { Navigator.of(context).pop(); } catch (e) {} }
               });
               return const Scaffold(body: Center(child: Text("Error: Torneo no activo.")));
           }
           if (provider.isTournamentFinished) {
              // El listener se encarga de navegar, mostramos carga mientras
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
           }

      return Scaffold(
        appBar: AppBar(
          title: Text('Torneo (${provider.participantCount} Jugadores)'),
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
                                      Navigator.of(ctx).pop();
                                      context.read<TournamentProvider>().resetTournament();
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
        // ---> BODY ACTUALIZADO CON FONDO <---
        body: Container( // 1. Contenedor para el fondo
          decoration: BoxDecoration(
            image: DecorationImage(
              // --> CAMBIA ESTO POR TU IMAGEN DE FONDO DEL TORNEO <--
              image: const AssetImage('assets/images/tournament_bg.png'), // Ejemplo! Usa tu imagen
              fit: BoxFit.cover,
              // Opcional: Filtro para oscurecer
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.7), // Ajusta opacidad
                BlendMode.darken,
              ),
            ),
          ),
          child: InteractiveViewer( // 2. InteractiveViewer como hijo
            transformationController: _transformationController,
            minScale: 0.2,
            maxScale: 4.0,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(50.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBracketLayout(context, provider.rounds, provider.participantCount),
            ),
          ),
        ),
        // ---> FIN BODY ACTUALIZADO <---
        floatingActionButton: FloatingActionButton(
          mini: true,
          tooltip: 'Centrar Vista',
          onPressed: () => _transformationController.value = Matrix4.identity(),
          child: const Icon(Icons.center_focus_strong),
        ),
      );
    });
  }

  // --- Función para construir el Layout del Bracket ---
  Widget _buildBracketLayout(BuildContext context, List<List<Match>> rounds, int participantCount) {
     if (rounds.isEmpty) {
       return const Center(child: Text("Generando bracket...", style: TextStyle(color: Colors.white))); // Texto blanco sobre fondo oscuro
     }
     switch (participantCount) {
       case 2: return _buildLayoutFor2(rounds);
       case 4: return _buildLayoutFor4(rounds);
       case 8: return _buildLayoutFor8(rounds);
       case 16: return _buildLayoutFor16(rounds);
       default: return Center(child: Text("Número de participantes ($participantCount) no soportado.", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange)));
     }
  }

  // --- Layouts Específicos ---
  Widget _buildLayoutFor2(List<List<Match>> rounds) {
     if (rounds.isEmpty || rounds[0].isEmpty) return const SizedBox.shrink();
     return Center(child: MatchWidget(match: rounds[0][0], widgetWidth: 200, nameFontSize: 14));
  }
  Widget _buildLayoutFor4(List<List<Match>> rounds) {
     if (rounds.length < 2 || rounds[0].isEmpty || rounds[1].isEmpty) return const SizedBox.shrink();
     final semiFinals = rounds[0];
     final finalMatch = rounds[1][0];
     return Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center,
        children: [ MatchWidget(match: semiFinals[0]), const SizedBox(width: 50), MatchWidget(match: finalMatch, widgetWidth: 180, nameFontSize: 14), const SizedBox(width: 50), MatchWidget(match: semiFinals[1]), ],
     );
  }
  Widget _buildLayoutFor8(List<List<Match>> rounds) {
    if (rounds.length < 3) return const SizedBox.shrink();
    final quarterFinals = rounds[0];
    final semiFinals = rounds[1];
    final finalMatch = rounds[2][0];
    Widget buildRoundColumn(List<Match> matches, {double spacing = 40.0}) {
        List<Widget> columnChildren = [];
        for (int i = 0; i < matches.length; i++) { columnChildren.add(MatchWidget(match: matches[i])); if (i < matches.length - 1) { columnChildren.add(SizedBox(height: spacing)); } }
        return Column( mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: columnChildren );
    }
    List<Match> getMatchesForSide(List<Match> roundMatches, bool isLeftSide) { int half = (roundMatches.length / 2).ceil(); return isLeftSide ? roundMatches.sublist(0, half) : roundMatches.sublist(half); }
    return Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center,
      children: [ buildRoundColumn(getMatchesForSide(quarterFinals, true), spacing: 80), const SizedBox(width: 40), buildRoundColumn(getMatchesForSide(semiFinals, true), spacing: 0), const SizedBox(width: 50), MatchWidget(match: finalMatch, widgetWidth: 180, nameFontSize: 16), const SizedBox(width: 50), buildRoundColumn(getMatchesForSide(semiFinals, false), spacing: 0), const SizedBox(width: 40), buildRoundColumn(getMatchesForSide(quarterFinals, false), spacing: 80), ],
    );
  }
  Widget _buildLayoutFor16(List<List<Match>> rounds) {
    if (rounds.length < 4) return const SizedBox.shrink();
    final roundOf16 = rounds[0]; final quarterFinals = rounds[1]; final semiFinals = rounds[2]; final finalMatch = rounds[3][0];
    Widget buildRoundColumn(List<Match> matches, {double spacing = 30.0}) { List<Widget> c = []; for(int i=0;i<matches.length;i++){ c.add(MatchWidget(match:matches[i])); if(i<matches.length-1){c.add(SizedBox(height:spacing));}} return Column(mainAxisAlignment:MainAxisAlignment.center,mainAxisSize:MainAxisSize.min,children:c); }
    List<Match> getMatchesForSide(List<Match> m, bool l){int h=(m.length/2).ceil();return l?m.sublist(0,h):m.sublist(h);}
    return Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center,
      children: [ buildRoundColumn(getMatchesForSide(roundOf16, true), spacing: 20), const SizedBox(width: 40), buildRoundColumn(getMatchesForSide(quarterFinals, true), spacing: 80), const SizedBox(width: 40), buildRoundColumn(getMatchesForSide(semiFinals, true), spacing: 180), const SizedBox(width: 60), MatchWidget(match: finalMatch, widgetWidth: 180, nameFontSize: 16), const SizedBox(width: 60), buildRoundColumn(getMatchesForSide(semiFinals, false), spacing: 180), const SizedBox(width: 40), buildRoundColumn(getMatchesForSide(quarterFinals, false), spacing: 80), const SizedBox(width: 40), buildRoundColumn(getMatchesForSide(roundOf16, false), spacing: 20), ],
    );
  }
} // Fin _TournamentScreenState
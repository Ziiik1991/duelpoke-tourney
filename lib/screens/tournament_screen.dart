import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Importaciones de nuestro proyecto
import '../providers/tournament_provider.dart';
import '../widgets/match_slot.dart';
import '../models/match.dart';
import '../services/audio_manager.dart';
import 'welcome_screen.dart';
import 'final_screen.dart';
import '../constants/layout_constants.dart'; // Constantes
// Importaciones de Flutter/Dart
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'dart:math'; // Para max

/// Pantalla principal donde se visualiza y juega el bracket del torneo.
/// USA LAYOUT LINEAL (IZQ -> DER) con Y Centrada por Padres.
class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});
  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final TransformationController _transformationController = TransformationController();
  TournamentProvider? _tournamentProviderRef;

  // --- Variables de Estado ---
  double _anchoTotalBracket = 0;
  double _altoTotalBracket = 0;
  Map<String, Offset> _posicionesPartidos = {};

  @override
  void initState() { super.initState(); _tournamentProviderRef = context.read<TournamentProvider>(); WidgetsBinding.instance.addPostFrameCallback((_) { final p = _tournamentProviderRef; if (p != null && mounted) { p.addListener(_onTournamentUpdate); _recalculateLayout(); } }); }
  @override
  void dispose() { if (_tournamentProviderRef != null) { try { _tournamentProviderRef!.removeListener(_onTournamentUpdate); } catch (e) { if (kDebugMode) print("Err removing listener: $e"); } } _transformationController.dispose(); super.dispose(); }
  void _onTournamentUpdate() { if (!mounted) return; final p = _tournamentProviderRef; if (p == null) return; if (kDebugMode) print("TournamentProvider updated, checking finish state..."); _checkIfTournamentFinished(p); }
  void _checkIfTournamentFinished(TournamentProvider p) { if (p.isTournamentFinished && p.winner != null) { if (kDebugMode) print("Tournament finished! Navigating to FinalScreen..."); try { p.removeListener(_onTournamentUpdate); } catch (e) { if (kDebugMode) print("Err removing listener during finish check: $e"); } AudioManager.instance.stopBackgroundMusic(); AudioManager.instance.playWinTournamentSound(); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => const FinalScreen()), ); } }); } }
  String _getRoundTitle(int roundIndex, int totalRounds) { if (totalRounds <= 1 && roundIndex == 0) return 'Final'; if (roundIndex == totalRounds - 1) return 'Final'; if (roundIndex == totalRounds - 2) return 'Semifinal'; if (roundIndex == totalRounds - 3) return 'Cuartos'; if (roundIndex == totalRounds - 4) return 'Octavos'; return 'Ronda ${roundIndex + 1}'; }
  void _playClickSound() { AudioManager.instance.playClickSound(); }
  void _resetTournament() { _playClickSound(); showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Reiniciar Torneo'), content: const Text('¿Seguro?'), actions: [ TextButton(child: const Text('Cancelar'), onPressed: () { _playClickSound(); Navigator.of(ctx).pop(); }, ), TextButton(child: const Text('Reiniciar', style: TextStyle(color: Colors.redAccent)), onPressed: () { _playClickSound(); Navigator.of(ctx).pop(); context.read<TournamentProvider>().resetTournament(); Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => const WelcomeScreen()), (Route<dynamic> route) => false, ); }, ), ], ), ); }
  void _goBack() { _playClickSound(); showDialog<bool>( context: context, builder: (ctx) => AlertDialog( title: const Text("Salir del Torneo"), content: const Text("El progreso no guardado se perderá."), actions: [ TextButton(onPressed: ()=> Navigator.of(ctx).pop(false), child: Text("Cancelar")), TextButton(onPressed: ()=> Navigator.of(ctx).pop(true), child: Text("Salir", style: TextStyle(color: Colors.redAccent))), ], ) ).then((confirmExit) { if (confirmExit == true) { if (kDebugMode) print("User chose to exit. Resetting and popping."); context.read<TournamentProvider>().resetTournament(); if(mounted) { Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => const WelcomeScreen()), (r) => false); } } else { if (kDebugMode) print("Exit dialog dismissed or cancelled."); } }); }


  /// Calcula layout LINEAL Izq->Der PERO CENTRANDO Y CON PADRES. (Corregido)
  void _recalculateLayout() {
    final provider = context.read<TournamentProvider>();
    final List<List<Match>> rondas = provider.rounds; // <-- Usar 'rondas' consistentemente

    if (rondas.isEmpty) { if(mounted) setState(() { _anchoTotalBracket = 0; _altoTotalBracket = 0; _posicionesPartidos.clear(); }); return; }
    final int rondasTotales = rondas.length; // <-- Usa 'rondas'

    if (kDebugMode) print("Calculating LINEAR layout (Parent Avg Y) for $rondasTotales rounds...");
    Map<String, Offset> nuevasPosiciones = {};
    double maxAlturaCalculada = 0;
    double maxAnchoCalculado = 0;

    final double espaciadoVerticalBase = kVerticalSpacing;
    final double pasoHorizontal = kMatchWidth + kHorizontalSpacing;
    final double inicioY = kMatchHeight * 1.5;

    for (int r = 0; r < rondasTotales; r++) {
      int partidosEnEstaRonda = rondas[r].length; // <-- Usa 'rondas'
      if (partidosEnEstaRonda == 0) continue;
      double actualX = r * pasoHorizontal;
      maxAnchoCalculado = max(maxAnchoCalculado, actualX + kMatchWidth);

      for (int m = 0; m < partidosEnEstaRonda; m++) {
          // Usa 'rondas' consistentemente
          if (m >= rondas[r].length) continue;
          Match partido = rondas[r][m];
          double actualY;

          if (r == 0) {
              actualY = inicioY + m * espaciadoVerticalBase; // R0 usa espaciado simple
          } else {
             int indicePadre1 = m * 2; int indicePadre2 = indicePadre1 + 1;
             // Usa 'rondas' consistentemente
             int partidosEnRondaAnterior = rondas[r-1].length;
             Match? partidoPadre1 = (indicePadre1 < partidosEnRondaAnterior) ? rondas[r-1][indicePadre1] : null;
             Match? partidoPadre2 = (indicePadre2 < partidosEnRondaAnterior) ? rondas[r-1][indicePadre2] : null;
             Offset? posPadre1 = partidoPadre1 != null ? nuevasPosiciones[partidoPadre1.id] : null;
             Offset? posPadre2 = partidoPadre2 != null ? nuevasPosiciones[partidoPadre2.id] : null;

             if (posPadre1 != null && posPadre2 != null) { actualY = ((posPadre1.dy + kMatchHeight / 2) + (posPadre2.dy + kMatchHeight / 2)) / 2 - (kMatchHeight / 2); }
             else if (posPadre1 != null) { actualY = posPadre1.dy; } else if (posPadre2 != null) { actualY = posPadre2.dy; }
             else { actualY = inicioY; if (kDebugMode) print("WARN: No parents found R:$r M:$m"); }
          }

          nuevasPosiciones[partido.id] = Offset(actualX, actualY);
          maxAlturaCalculada = max(maxAlturaCalculada, actualY + kMatchHeight);
          // if (kDebugMode) { print(" Linear Layout - Rendering Match R:${partido.roundIndex} M:${partido.matchIndexInRound} at Pos: (${actualX.toStringAsFixed(1)}, ${actualY.toStringAsFixed(1)})"); }
      }
    }

    double anchoFinal = maxAnchoCalculado + kHorizontalSpacing;
    double altoFinal = maxAlturaCalculada + kMatchHeight * 1.5;

    if (kDebugMode) { print("Linear Layout Calculation Done (Parent Avg Y)."); print("Final Total Width: $anchoFinal"); print("Final Total Height: $altoFinal"); print("Positions calculated for ${nuevasPosiciones.length} matches."); }

    if(mounted) {
       setState(() {
           _posicionesPartidos = nuevasPosiciones;
           _anchoTotalBracket = anchoFinal; // <-- Usar anchoFinal
           _altoTotalBracket = altoFinal;   // <-- Usar altoFinal
       });
    }
  }
  // --- FIN _recalculateLayout ---


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final int rondasTotales = provider.rounds.length;

    if (!provider.isTournamentActive && !provider.isTournamentFinished) { return const Scaffold(body: Center(child: Text("Redirigiendo..."))); }
    if (provider.isTournamentFinished && provider.winner != null) { return const Scaffold(body: Center(child: CircularProgressIndicator())); }

    List<Widget> stackChildren = [];
    final double pasoHorizontal = kMatchWidth + kHorizontalSpacing;
    double anchoActual = _anchoTotalBracket; double altoActual = _altoTotalBracket;
    if (_posicionesPartidos.isNotEmpty) { double maxX = 0; double maxY = 0; for(Offset pos in _posicionesPartidos.values) { maxX = max(maxX, pos.dx + kMatchWidth); maxY = max(maxY, pos.dy + kMatchHeight); } anchoActual = max(_anchoTotalBracket, maxX + kHorizontalSpacing); altoActual = max(_altoTotalBracket, maxY + kMatchHeight * 1.5); }

    // --- ORDEN: Líneas -> Partidos -> Títulos ---

    // 1. Painter (Lineal)
    if (_posicionesPartidos.isNotEmpty && rondasTotales > 0) {
       stackChildren.add( CustomPaint( painter: BracketLinesPainter( rounds: provider.rounds, positions: _posicionesPartidos, ), size: Size(anchoActual, altoActual), ) );
    }

    // 2. Partidos (Usa MatchSlot)
    if (_posicionesPartidos.isNotEmpty) {
      stackChildren.addAll( provider.rounds.expand((ronda) => ronda).map((partido) { final posicion = _posicionesPartidos[partido.id]; if (posicion == null) { return const SizedBox.shrink(); }
            final Widget widgetSlot = MatchSlot(match: partido);
            if (kDebugMode) { print("Rendering Match R:${partido.roundIndex} M:${partido.matchIndexInRound} at Pos: (${posicion.dx.toStringAsFixed(1)}, ${posicion.dy.toStringAsFixed(1)})"); }
            return Positioned( left: posicion.dx, top: posicion.dy, child: widgetSlot, );
           }) );
    } else if (provider.rounds.isNotEmpty) { stackChildren.add(const Center(child: CircularProgressIndicator())); }

    // 3. Títulos (Lineales)
     if (_posicionesPartidos.isNotEmpty && rondasTotales > 0 && anchoActual > 0) {
       final double tituloY = 10.0; const estiloTitulo = TextStyle( color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14, shadows: [ Shadow(color: Colors.black, offset: Offset(1,1), blurRadius: 2) ] );
       for (int r = 0; r < rondasTotales; r++) { String textoTitulo = _getRoundTitle(r, rondasTotales); double tituloX = r * pasoHorizontal; stackChildren.add( Positioned( left: tituloX, top: tituloY, width: kMatchWidth, child: Text( textoTitulo, textAlign: TextAlign.center, style: estiloTitulo, ), ), ); }
     }

    // --- Construcción del Scaffold ---
    return Scaffold(
       appBar: AppBar( title: Text('Torneo (${provider.participantCount} Jugadores)'), actions: [ IconButton( icon: const Icon(Icons.undo), tooltip: 'Deshacer', onPressed: provider.canUndo ? () { _playClickSound(); context.read<TournamentProvider>().undoLastSelection(); } : null, ), IconButton( icon: const Icon(Icons.refresh), tooltip: 'Reiniciar', onPressed: _resetTournament, ), ], leading: IconButton( icon: const Icon(Icons.arrow_back), tooltip: 'Salir', onPressed: _goBack, ), ),
       body: Container( decoration: BoxDecoration( image: DecorationImage( image: const AssetImage('assets/images/tournament_bg.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode( Colors.black.withOpacity(0.7), BlendMode.darken,), ),), child: InteractiveViewer( transformationController: _transformationController, minScale: 0.1, maxScale: 5.0, constrained: false, boundaryMargin: const EdgeInsets.all(200.0), child: SizedBox( width: anchoActual, height: altoActual, child: Stack( children: stackChildren ), ), ), ),
       floatingActionButton: FloatingActionButton( mini: true, tooltip: 'Centrar Vista', onPressed: () { if (kDebugMode) print("Resetting view transformation."); _transformationController.value = Matrix4.identity(); }, child: const Icon(Icons.center_focus_strong), ),
    );
  }
} // Fin clase _TournamentScreenState


/// Dibuja las líneas conectores para un bracket LINEAL (Izq -> Der).
class BracketLinesPainter extends CustomPainter {
  final List<List<Match>> rounds; final Map<String, Offset> positions;
  final Paint linePaint;
  BracketLinesPainter({ required this.rounds, required this.positions, }) : linePaint = Paint() ..color = Colors.grey[600]! ..strokeWidth = 1.5 ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Usa constantes globales importadas
    const double matchHeight = kMatchHeight; const double matchWidth = kMatchWidth; const double hSpacing = kHorizontalSpacing;

    if (rounds.isEmpty || positions.isEmpty) return;
    final int rondasTotales = rounds.length; // Español

    for (int r = 0; r < rondasTotales - 1; r++) {
      int partidosEnEstaRonda = rounds[r].length; // Español
      if(partidosEnEstaRonda == 0) continue;

      for (int m = 0; m < partidosEnEstaRonda; m++) {
        if (m >= rounds[r].length) continue;
        final Match partidoActual = rounds[r][m]; // Español
        final Offset? posActual = positions[partidoActual.id]; // Español
        if (posActual == null) { continue; }

        int siguienteIndicePartido = (m / 2).floor(); // Español
        if (r + 1 < rondasTotales && siguienteIndicePartido < rounds[r + 1].length) {
          final Match siguientePartido = rounds[r + 1][siguienteIndicePartido]; // Español
          final Offset? siguientePos = positions[siguientePartido.id]; // Español
          if (siguientePos == null) { continue; }

          // Lógica lineal Izq -> Der
          final Offset puntoSalida = Offset(posActual.dx + matchWidth, posActual.dy + matchHeight / 2);
          final Offset puntoEntrada = Offset(siguientePos.dx, siguientePos.dy + matchHeight / 2);
          final double medioX = puntoSalida.dx + hSpacing / 2;
          final Path camino = Path();
          camino.moveTo(puntoSalida.dx, puntoSalida.dy);
          camino.lineTo(medioX, puntoSalida.dy); // Horizontal
          camino.lineTo(medioX, puntoEntrada.dy); // Vertical
          camino.lineTo(puntoEntrada.dx, puntoEntrada.dy); // Horizontal
          canvas.drawPath(camino, linePaint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant BracketLinesPainter oldDelegate) {
    // Comparar solo datos que sí tiene la clase
    return oldDelegate.positions != positions || oldDelegate.rounds != rounds;
   }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../widgets/match_widget.dart';
import '../models/match.dart';
import '../services/audio_manager.dart';
import 'welcome_screen.dart';
import 'final_screen.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'dart:math'; // Para pow (aunque ya no se usa en VSpacing)

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final TransformationController _transformationController = TransformationController();
  TournamentProvider? _tournamentProviderRef;

  // --- Constantes de Layout ---
  static const double _matchHeight = 85.0; // Altura ajustada previamente
  static const double _matchWidth = 150.0;
  static const double _hSpacing = 60.0; // Espacio horizontal entre widgets
  static const double _baseVSpacingMultiplier = 0.05; // ESPACIO MÍNIMO (5% gap)

  // --- Variables Calculadas para Stack ---
  double _totalBracketWidth = 0;
  double _totalBracketHeight = 0;
  final Map<String, Offset> _matchPositions = {}; // Guarda {match.id: Offset(x,y)}

  @override
  void initState() {
    super.initState();
    _tournamentProviderRef = context.read<TournamentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = _tournamentProviderRef;
      if (p != null && mounted) {
        p.addListener(_onTournamentUpdate);
        _calculateLayout(p.rounds);
      }
    });
  }

  @override
  void dispose() {
    if (_tournamentProviderRef != null) {
      try {
        _tournamentProviderRef!.removeListener(_onTournamentUpdate);
      } catch (e) {
        if (kDebugMode) print("Err removing listener: $e");
      }
    }
    _transformationController.dispose();
    super.dispose();
  }

  void _onTournamentUpdate() {
     if (!mounted) return;
     final p = _tournamentProviderRef;
     if (p == null) return;
     _checkIfTournamentFinished(p);
  }

  void _checkIfTournamentFinished(TournamentProvider p) {
     if (p.isTournamentFinished && p.winner != null) {
      try {
        p.removeListener(_onTournamentUpdate);
      } catch (e) { if (kDebugMode) print("Err removing listener: $e"); }
      AudioManager.instance.stopBackgroundMusic();
      AudioManager.instance.playWinTournamentSound();
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
           Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const FinalScreen()),
           );
         }
      });
    }
  }

  String _getRoundTitle(int roundIndex, int totalRounds) {
      if (totalRounds <= 1 && roundIndex == 0) return 'Final';
      if (totalRounds == 4) { if (roundIndex == 3) return 'Final'; if (roundIndex == 2) return 'Semifinal'; if (roundIndex == 1) return 'Cuartos'; if (roundIndex == 0) return 'Octavos'; }
      if (totalRounds == 3) { if (roundIndex == 2) return 'Final'; if (roundIndex == 1) return 'Semifinal'; if (roundIndex == 0) return 'Cuartos'; }
      if (totalRounds == 2) { if (roundIndex == 1) return 'Final'; if (roundIndex == 0) return 'Semifinal'; }
      if (totalRounds == 1) { return 'Final'; }
      return 'Ronda ${roundIndex + 1}';
  }

  void _playClickSound() { AudioManager.instance.playClickSound(); }

  void _resetTournament() { /* ... (código igual que antes) ... */
      _playClickSound(); showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Reiniciar Torneo'), content: const Text('¿Seguro?'), actions: [ TextButton(child: const Text('Cancelar'), onPressed: () { _playClickSound(); Navigator.of(ctx).pop(); }, ), TextButton(child: const Text('Reiniciar', style: TextStyle(color: Colors.redAccent)), onPressed: () { _playClickSound(); Navigator.of(ctx).pop(); context.read<TournamentProvider>().resetTournament(); Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => const WelcomeScreen()), (Route<dynamic> route) => false, ); }, ), ], ), );
  }

  void _goBack() { /* ... (código igual que antes) ... */
      _playClickSound(); showDialog( context: context, builder: (ctx) => AlertDialog( title: const Text("Salir"), content: const Text("¿Seguro?"), actions: [ TextButton(onPressed: (){ _playClickSound(); Navigator.of(ctx).pop(); }, child: const Text("Cancelar")), TextButton( onPressed: () { _playClickSound(); Navigator.of(ctx).pop(); context.read<TournamentProvider>().resetTournament(); Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => const WelcomeScreen()), (r) => false); }, child: const Text("Salir", style: TextStyle(color: Colors.redAccent)), ) ], ), );
  }

  // Calcula layout con ESPACIADO VERTICAL FIJO Y MÍNIMO (usando _baseVSpacingMultiplier = 0.05)
  void _calculateLayout(List<List<Match>> rounds) {
    if (rounds.isEmpty) {
       if(mounted) setState(() { _totalBracketWidth = 0; _totalBracketHeight = 0; _matchPositions.clear(); });
       return;
    }
    final int totalRounds = rounds.length;
    if (totalRounds == 0) {
       if(mounted) setState(() { _totalBracketWidth = 0; _totalBracketHeight = 0; _matchPositions.clear(); });
       return;
    }

    _matchPositions.clear();
    double maxCalculatedHeight = 0;
    double calculatedWidth = 0;

    // --- Espaciado Vertical FIJO ---
    // El espaciado ahora es constante y mínimo
    double verticalSpacing = _matchHeight + _baseVSpacingMultiplier * _matchHeight; // Usa 0.05
    // --- Fin Cálculo Espaciado Vertical ---

    for (int r = 0; r < totalRounds; r++) {
      int matchesInThisRound = rounds[r].length;
      if (matchesInThisRound == 0) continue;

      double currentX = r * (_matchWidth + _hSpacing);
      calculatedWidth = max(calculatedWidth, currentX + _matchWidth);
      double startY = _matchHeight; // Y inicial simple

      for (int m = 0; m < matchesInThisRound; m++) {
          if (m < rounds[r].length) {
             Match match = rounds[r][m];
             // Calcular Y usando el espaciado fijo mínimo
             double currentY = startY + m * verticalSpacing;
             _matchPositions[match.id] = Offset(currentX, currentY);
             maxCalculatedHeight = max(maxCalculatedHeight, currentY + _matchHeight);
          } else {
             if (kDebugMode) print("WARN: Index M=$m out of bounds for Round R=$r");
          }
      }
    }

    _totalBracketWidth = calculatedWidth + _matchWidth;
    _totalBracketHeight = maxCalculatedHeight + _matchHeight; // Altura total basada en contenido

    if (kDebugMode) {
      print("Layout Calculation Done (Fixed Minimal Spacing).");
      print("Total Bracket Width: $_totalBracketWidth");
      print("Total Bracket Height: $_totalBracketHeight"); // Será el más compacto
      print("Positions calculated for ${_matchPositions.length} matches.");
    }

    if(mounted) {
       setState(() {});
    }
  } // Fin _calculateLayout

  // Widget _buildMatchSlotWidgetV4 (igual que antes)
  Widget _buildMatchSlotWidgetV4(Match? match) {
      final double slotHeight = _matchHeight;
      final double slotWidth = _matchWidth;
      return SizedBox( height: slotHeight, width: slotWidth, child: Builder( builder: (context) { /* ... (código igual que antes) ... */ if (match == null) { return Container( height: slotHeight, width: slotWidth, decoration: BoxDecoration( color: Colors.grey[800]?.withOpacity(0.3), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[700]!, style: BorderStyle.solid), ), child: Center(child: Text("?", style: TextStyle(color: Colors.grey[600]))), ); } else if (match.isBye && match.winner != null) { return Container( padding: const EdgeInsets.all(4), decoration: BoxDecoration( color: Colors.blueGrey.shade700.withOpacity(0.7), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[600]!) ), child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [ Text( match.winner!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,), const SizedBox(height: 4), Text( "(BYE)", style: TextStyle(color: Colors.cyanAccent.withOpacity(0.8), fontSize: 10, fontStyle: FontStyle.italic),), ] ), ); } else { return MatchWidget(match: match, widgetWidth: slotWidth); } }, ), );
    }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final int totalRounds = provider.rounds.length;

    // --- Verificaciones iniciales (igual que antes) ---
    if (!provider.isTournamentActive && !provider.isTournamentFinished) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) { Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => const WelcomeScreen()), (route) => false ); } }); return const Scaffold(body: Center(child: Text("Redirigiendo..."))); }
    if (provider.isTournamentFinished && provider.winner != null) { return const Scaffold(body: Center(child: CircularProgressIndicator())); }

    // --- Construcción Condicional de Hijos del Stack ---
    List<Widget> stackChildren = [];

    // 1. Añadir CustomPaint para líneas
    if (_matchPositions.isNotEmpty && totalRounds > 0) {
       stackChildren.add( CustomPaint( painter: BracketLinesPainter( rounds: provider.rounds, positions: _matchPositions, matchHeight: _matchHeight, matchWidth: _matchWidth, hSpacing: _hSpacing, ), size: Size(_totalBracketWidth, _totalBracketHeight), ) );
    }

    // 2. Añadir Títulos de Ronda
     if (_matchPositions.isNotEmpty && totalRounds > 0) {
       for (int r = 0; r < totalRounds; r++) {
         double titleX = r * (_matchWidth + _hSpacing);
         double titleY = _matchHeight * 0.3;
         stackChildren.add( Positioned( left: titleX, top: titleY, width: _matchWidth, child: Text( _getRoundTitle(r, totalRounds), textAlign: TextAlign.center, style: const TextStyle( color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14, shadows: [ Shadow(color: Colors.black, offset: Offset(1,1), blurRadius: 2) ] ), ), ), );
       }
     }

    // 3. Añadir widgets de partidos
    if (_matchPositions.isNotEmpty) {
      stackChildren.addAll( provider.rounds.expand((round) => round).map((match) { final position = _matchPositions[match.id]; if (position == null) { if (kDebugMode) print("WARN: No position found for match ${match.id}"); return const SizedBox.shrink(); } final matchSlotWidget = _buildMatchSlotWidgetV4(match); return Positioned( left: position.dx, top: position.dy, child: matchSlotWidget, ); }) );
    } else if (provider.rounds.isNotEmpty) {
      stackChildren.add(const Center(child: CircularProgressIndicator()));
    }

    // --- Construcción del Scaffold (igual que antes) ---
    return Scaffold( appBar: AppBar( title: Text('Torneo (${provider.participantCount} Jugadores)'), actions: [ IconButton( icon: const Icon(Icons.undo), tooltip: 'Deshacer Última Selección', onPressed: provider.canUndo ? () { _playClickSound(); context.read<TournamentProvider>().undoLastSelection(); } : null, ), IconButton( icon: const Icon(Icons.refresh), tooltip: 'Reiniciar Torneo', onPressed: _resetTournament, ), ], leading: IconButton( icon: const Icon(Icons.arrow_back), tooltip: 'Salir del Torneo', onPressed: _goBack, ), ), body: Container( decoration: BoxDecoration( image: DecorationImage( image: const AssetImage('assets/images/tournament_bg.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode( Colors.black.withOpacity(0.7), BlendMode.darken,), ),), child: InteractiveViewer( transformationController: _transformationController, minScale: 0.1, maxScale: 4.0, constrained: false, boundaryMargin: const EdgeInsets.all(150.0), child: SizedBox( width: _totalBracketWidth, height: _totalBracketHeight, child: Stack( children: stackChildren, ), ), ), ), floatingActionButton: FloatingActionButton( mini: true, tooltip: 'Centrar Vista', onPressed: () => _transformationController.value = Matrix4.identity(), child: const Icon(Icons.center_focus_strong), ), );
  } // Fin build

} // Fin _TournamentScreenState


// --- Clase BracketLinesPainter (igual que antes) ---
class BracketLinesPainter extends CustomPainter {
  final List<List<Match>> rounds; final Map<String, Offset> positions; final double matchHeight; final double matchWidth; final double hSpacing; final Paint linePaint;
  BracketLinesPainter({ required this.rounds, required this.positions, required this.matchHeight, required this.matchWidth, required this.hSpacing, }) : linePaint = Paint() ..color = Colors.grey[600]! ..strokeWidth = 1.5 ..style = PaintingStyle.stroke;
  @override void paint(Canvas canvas, Size size) { /* ... (código igual que antes) ... */ if (rounds.isEmpty || positions.isEmpty) return; final int totalRounds = rounds.length; for (int r = 0; r < totalRounds - 1; r++) { for (int m = 0; m < rounds[r].length; m++) { final Match currentMatch = rounds[r][m]; final Offset? currentPos = positions[currentMatch.id]; if (currentPos == null) { continue; } int nextMatchIndex = (m / 2).floor(); if (r + 1 < totalRounds && nextMatchIndex < rounds[r + 1].length) { final Match nextMatch = rounds[r + 1][nextMatchIndex]; final Offset? nextPos = positions[nextMatch.id]; if (nextPos == null) { continue; } final Offset outPoint = Offset(currentPos.dx + matchWidth, currentPos.dy + matchHeight / 2); final Offset inPoint = Offset(nextPos.dx, nextPos.dy + matchHeight / 2); final double midX = currentPos.dx + matchWidth + hSpacing / 2; final Path path = Path(); path.moveTo(outPoint.dx, outPoint.dy); path.lineTo(midX, outPoint.dy); path.lineTo(midX, inPoint.dy); path.lineTo(inPoint.dx, inPoint.dy); canvas.drawPath(path, linePaint); } } } }
  @override bool shouldRepaint(covariant BracketLinesPainter oldDelegate) { return oldDelegate.positions != positions || oldDelegate.rounds != rounds; }
}
// --- Fin BracketLinesPainter ---
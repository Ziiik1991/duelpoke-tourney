import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../widgets/match_widget.dart';
import '../models/match.dart';
import '../services/audio_manager.dart';
import 'welcome_screen.dart';
import 'final_screen.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'dart:math'; // Para pow y max

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final TransformationController _transformationController = TransformationController();
  TournamentProvider? _tournamentProviderRef;

  // --- Constantes de Layout ---
  static const double _matchHeight = 85.0;
  static const double _matchWidth = 120.0;
  static const double _hSpacing = 250.0; // Espacio horizontal aumentado
  static const double _baseVSpacingMultiplier = 0.05;

  // --- Variables Calculadas para Stack ---
  double _totalBracketWidth = 0;
  double _totalBracketHeight = 0;
  Map<String, Offset> _matchPositions = {};

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
      try { _tournamentProviderRef!.removeListener(_onTournamentUpdate); }
      catch (e) { if (kDebugMode) print("Err removing listener: $e"); }
    }
    _transformationController.dispose();
    super.dispose();
  }

  void _onTournamentUpdate() {
     if (!mounted) return;
     final p = _tournamentProviderRef;
     if (p == null) return;
      if (kDebugMode) print("TournamentProvider updated, checking finish state...");
     _checkIfTournamentFinished(p);
  }

  void _checkIfTournamentFinished(TournamentProvider p) {
     if (p.isTournamentFinished && p.winner != null) {
      if (kDebugMode) print("Tournament finished! Winner: ${p.winner?.name}");
      try { p.removeListener(_onTournamentUpdate); }
      catch (e) { if (kDebugMode) print("Err removing listener during finish check: $e"); }
      AudioManager.instance.stopBackgroundMusic();
      AudioManager.instance.playWinTournamentSound();
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
           Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => const FinalScreen()), );
         }
      });
    }
  }

 String _getRoundTitle(int roundIndex, int totalRounds) {
      if (totalRounds <= 1 && roundIndex == 0) return 'Final';
      if (roundIndex == totalRounds - 1) return 'Final';
      if (roundIndex == totalRounds - 2) return 'Semifinal';
      if (roundIndex == totalRounds - 3) return 'Cuartos';
      if (roundIndex == totalRounds - 4) return 'Octavos';
      if (roundIndex == totalRounds - 5) return 'Ronda de 32';
      if (roundIndex == totalRounds - 6) return 'Ronda de 64';
      if (roundIndex == totalRounds - 7) return 'Ronda de 128';
      return 'Ronda ${roundIndex + 1}';
  }

  void _playClickSound() { AudioManager.instance.playClickSound(); }

  void _resetTournament() {
      _playClickSound();
      showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Reiniciar Torneo'), content: const Text('¿Seguro?'), actions: [ TextButton(child: const Text('Cancelar'), onPressed: () { _playClickSound(); Navigator.of(ctx).pop(); }, ), TextButton(child: const Text('Reiniciar', style: TextStyle(color: Colors.redAccent)), onPressed: () { _playClickSound(); Navigator.of(ctx).pop(); context.read<TournamentProvider>().resetTournament(); Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => const WelcomeScreen()), (Route<dynamic> route) => false, ); }, ), ], ), );
  }

  void _goBack() {
      _playClickSound();
      showDialog<bool>( context: context, builder: (ctx) => AlertDialog( title: const Text("Salir del Torneo"), content: const Text("¿Quieres guardar antes de salir? (Funcionalidad Guardar no implementada)"), actions: [ TextButton(onPressed: ()=> Navigator.of(ctx).pop(false), child: Text("Salir Sin Guardar")), /*TextButton(onPressed: ()=> Navigator.of(ctx).pop(true), child: Text("Guardar y Salir")),*/ ], )
      ).then((shouldSave) {
          if (shouldSave != null) {
             if (kDebugMode) print("User chose to exit (Save choice: $shouldSave - ignored). Resetting and popping.");
             context.read<TournamentProvider>().resetTournament();
             if(mounted) {
                Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => const WelcomeScreen()), (r) => false);
             }
          } else {
              if (kDebugMode) print("Exit dialog dismissed.");
          }
      });
  }


  // --- VERSIÓN _calculateLayout (Estimación de Ancho Mejorada - Attempt 8) ---
  void _calculateLayout(List<List<Match>> rounds) {
    if (rounds.isEmpty) { if(mounted) setState(() { _totalBracketWidth = 0; _totalBracketHeight = 0; _matchPositions.clear(); }); return; }
    final int totalRounds = rounds.length;
    if (totalRounds == 0) { if(mounted) setState(() { _totalBracketWidth = 0; _totalBracketHeight = 0; _matchPositions.clear(); }); return; }

    if (kDebugMode) print("Calculating MIRRORED layout (Better Width Estimate - Attempt 8) for $totalRounds rounds...");
    _matchPositions.clear();
    double maxCalculatedHeight = 0;
    double maxCalculatedWidth = 0;

    final double verticalSpacingBase = _matchHeight + _baseVSpacingMultiplier * _matchHeight;
    final double horizontalStep = _matchWidth + _hSpacing;

    // --- Estimación de Ancho Revisada ---
    // Ancho necesario ~ (N-1) pasos + ancho final + padding extra
    _totalBracketWidth = (totalRounds > 0 ? (totalRounds - 1) * horizontalStep : 0) + _matchWidth + (_hSpacing * 2); // Añadir padding extra
    final double centerX = _totalBracketWidth / 2;
    if (kDebugMode) print("REVISED Estimated Total Width: $_totalBracketWidth, CenterX: $centerX");
    // --- Fin Estimación Revisada ---


    // Calcular altura inicial basada en R0
    int maxMatchesPerSideInR0 = (rounds.isNotEmpty && rounds[0].isNotEmpty) ? (rounds[0].length / 2).ceil() : 0;
    _totalBracketHeight = (maxMatchesPerSideInR0 > 0 ? (maxMatchesPerSideInR0 - 1) * verticalSpacingBase : 0) + _matchHeight;
    _totalBracketHeight += _matchHeight * 3; // Padding

    // --- Calcular Posiciones Ronda 0 ---
    int matchesInRound0 = rounds.isNotEmpty ? rounds[0].length : 0;
    if (matchesInRound0 > 0) {
        int matchesOnLeftR0 = (matchesInRound0 / 2).floor();
        double startYR0 = _matchHeight * 1.5;
        for (int m = 0; m < matchesInRound0; m++) {
            if (m >= rounds[0].length) continue; Match match = rounds[0][m]; double currentX; bool isLeftBranch = m < matchesOnLeftR0; int matchIndexWithinSide = isLeftBranch ? m : m - matchesOnLeftR0;
            // Usar la NUEVA estimación de ancho para la derecha
            if (isLeftBranch) { currentX = 0; } else { currentX = _totalBracketWidth - _matchWidth; }
            double currentY = startYR0 + matchIndexWithinSide * verticalSpacingBase;
            _matchPositions[match.id] = Offset(currentX, currentY);
            maxCalculatedHeight = max(maxCalculatedHeight, currentY + _matchHeight); maxCalculatedWidth = max(maxCalculatedWidth, currentX + _matchWidth);
        }
    } else { _totalBracketHeight = _matchHeight * 5; }

    // --- Calcular Posiciones Rondas > 0 (Usando NUEVA estimación de ancho) ---
    for (int r = 1; r < totalRounds; r++) {
        int matchesInThisRound = rounds[r].length; int matchesInPreviousRound = rounds[r-1].length; if(matchesInThisRound == 0) continue;
        int matchesOnLeftPrev = (matchesInPreviousRound / 2).floor();
        for (int m = 0; m < matchesInThisRound; m++) {
            if (m >= rounds[r].length) continue; Match match = rounds[r][m]; double currentX; double currentY;
            int parentIndex1 = m * 2; int parentIndex2 = parentIndex1 + 1;
            Match? parentMatch1 = (parentIndex1 < matchesInPreviousRound) ? rounds[r-1][parentIndex1] : null; Match? parentMatch2 = (parentIndex2 < matchesInPreviousRound) ? rounds[r-1][parentIndex2] : null;
            Offset? parent1Pos = parentMatch1 != null ? _matchPositions[parentMatch1.id] : null; Offset? parent2Pos = parentMatch2 != null ? _matchPositions[parentMatch2.id] : null;
            // Calcular Y promediando padres
            if (parent1Pos != null && parent2Pos != null) { currentY = ((parent1Pos.dy + _matchHeight / 2) + (parent2Pos.dy + _matchHeight / 2)) / 2 - (_matchHeight / 2); }
            else if (parent1Pos != null) { currentY = parent1Pos.dy; } else if (parent2Pos != null) { currentY = parent2Pos.dy; }
            else { currentY = _matchHeight * 1.5; if (kDebugMode) print("WARN: No parents found R:$r M:$m"); }
            // Calcular X
            bool isFinalRound = r == totalRounds - 1;
             if (isFinalRound) {
                 // Centrar final basado en padres o fallback usando NUEVO centerX
                 if (parent1Pos != null && parent2Pos != null) { currentX = ((parent1Pos.dx + _matchWidth) + parent2Pos.dx) / 2 - (_matchWidth / 2); }
                 else { currentX = centerX - (_matchWidth / 2); } // Usa nuevo centerX
             } else {
                 // Posicionar ramas usando NUEVO _totalBracketWidth
                 bool parentIsLeft = parentIndex1 < matchesOnLeftPrev;
                 if (parentIsLeft) { currentX = r * horizontalStep; }
                 else { currentX = _totalBracketWidth - _matchWidth - (r * horizontalStep); } // Usa nuevo _totalBracketWidth
             }
             currentX = max(0, currentX);
             _matchPositions[match.id] = Offset(currentX, currentY);
             maxCalculatedHeight = max(maxCalculatedHeight, currentY + _matchHeight); maxCalculatedWidth = max(maxCalculatedWidth, currentX + _matchWidth);
        }
    }

    // Ajuste final de dimensiones
    _totalBracketWidth = max(_totalBracketWidth, maxCalculatedWidth + _hSpacing); // Usar ancho real + padding
    _totalBracketHeight = max(_totalBracketHeight, maxCalculatedHeight + _matchHeight * 1.5); // Usar alto real + padding

    if (kDebugMode) { print("Layout Calculation Done (Better Width Estimate - Attempt 8)."); print("Final Total Width: $_totalBracketWidth"); print("Final Total Height: $_totalBracketHeight"); print("Positions calculated for ${_matchPositions.length} matches."); }
    if(mounted) { setState(() {}); }
  }
  // --- FIN _calculateLayout ---


  // Widget _buildMatchSlotWidgetV4 (Sin cambios)
  Widget _buildMatchSlotWidgetV4(Match? match) {
      final double slotHeight = _matchHeight; final double slotWidth = _matchWidth; return Container( height: slotHeight, width: slotWidth, child: Builder( builder: (context) { if (match == null) { return Container( height: slotHeight, width: slotWidth, decoration: BoxDecoration( color: Colors.grey[800]?.withOpacity(0.3), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[700]!, style: BorderStyle.solid), ), child: Center(child: Text("?", style: TextStyle(color: Colors.grey[600]))), ); } else if (match.isBye) { if (match.winner != null) { return Container( padding: const EdgeInsets.all(4), decoration: BoxDecoration( color: Colors.blueGrey.shade700.withOpacity(0.7), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[600]!) ), child: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [ Text( match.winner!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,), const SizedBox(height: 4), Text( "(BYE)", style: TextStyle(color: Colors.cyanAccent.withOpacity(0.8), fontSize: 10, fontStyle: FontStyle.italic),), ] ), ); } else { return Container( height: slotHeight, width: slotWidth, padding: const EdgeInsets.all(4), decoration: BoxDecoration( color: Colors.red[900]?.withOpacity(0.5), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.redAccent) ), child: Center(child: Text("BYE ERR", style: TextStyle(color: Colors.white, fontSize: 10))), ); } } else { return MatchWidget( match: match, ); } }, ), );
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final int totalRounds = provider.rounds.length;

    if (!provider.isTournamentActive && !provider.isTournamentFinished) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) { Navigator.of(context).pushAndRemoveUntil( MaterialPageRoute(builder: (context) => const WelcomeScreen()), (route) => false ); } }); return const Scaffold(body: Center(child: Text("Redirigiendo..."))); }
    if (provider.isTournamentFinished && provider.winner != null) { return const Scaffold(body: Center(child: CircularProgressIndicator())); }

    List<Widget> stackChildren = [];

    // --- Recalcular ANCHO REAL en Build para precisión de títulos ---
    double currentTotalWidth = _totalBracketWidth; // Usar valor de estado como base
    double currentTotalHeight = _totalBracketHeight;
    if (_matchPositions.isNotEmpty) {
        double maxX = 0; double maxY = 0;
        for(Offset pos in _matchPositions.values) {
            maxX = max(maxX, pos.dx + _matchWidth);
            maxY = max(maxY, pos.dy + _matchHeight);
        }
        currentTotalWidth = max(_totalBracketWidth, maxX + _hSpacing);
        currentTotalHeight = max(_totalBracketHeight, maxY + _matchHeight * 1.5);
    }
    // --- Fin Recalculo ---

    final double horizontalStep = _matchWidth + _hSpacing;

    // 1. Painter (Usa painter corregido)
    if (_matchPositions.isNotEmpty && totalRounds > 0) {
       stackChildren.add( CustomPaint(
             painter: BracketLinesPainter(
               rounds: provider.rounds,
               positions: _matchPositions,
               matchHeight: _matchHeight,
               matchWidth: _matchWidth,
               hSpacing: _hSpacing,
             ),
             size: Size(currentTotalWidth, currentTotalHeight), // Usa tamaño recalculado
          )
       );
    }

    // 2. Partidos (Positioned)
    if (_matchPositions.isNotEmpty) {
      stackChildren.addAll( provider.rounds.expand((round) => round).map((match) { final position = _matchPositions[match.id]; if (position == null) { if (kDebugMode) print("WARN: No position found for match ${match.id} during build."); return const SizedBox.shrink(); }
            final matchSlotWidget = _buildMatchSlotWidgetV4(match);
            return Positioned( left: position.dx, top: position.dy, child: matchSlotWidget, );
           }) );
    } else if (provider.rounds.isNotEmpty) { stackChildren.add(const Center(child: CircularProgressIndicator())); }

    // 3. Títulos (Usa ancho recalculado)
     if (_matchPositions.isNotEmpty && totalRounds > 0 && currentTotalWidth > 0) {
       final double titleY = 10.0;
       const titleStyle = TextStyle( color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14, shadows: [ Shadow(color: Colors.black, offset: Offset(1,1), blurRadius: 2) ] );
       for (int r = 0; r < totalRounds; r++) {
         bool isFinalRound = r == totalRounds - 1;
         String titleText = _getRoundTitle(r, totalRounds);
         if(isFinalRound) {
            double titleX = (currentTotalWidth / 2) - (_matchWidth / 2); // Usa ancho recalculado
            titleX = max(0, titleX);
            stackChildren.add( Positioned( left: titleX, top: titleY, width: _matchWidth, child: Text( titleText, textAlign: TextAlign.center, style: titleStyle, ), ), );
         } else {
            double titleXLeft = r * horizontalStep;
            stackChildren.add( Positioned( left: titleXLeft, top: titleY, width: _matchWidth, child: Text( titleText, textAlign: TextAlign.center, style: titleStyle, ), ), );
            // Usa ancho recalculado para la derecha
            double titleXRight = currentTotalWidth - _matchWidth - (r * horizontalStep);
             if (titleXRight > 0) { // Solo añadir si es positivo
                 stackChildren.add( Positioned( left: titleXRight, top: titleY, width: _matchWidth, child: Text( titleText, textAlign: TextAlign.center, style: titleStyle, ), ), );
             }
         }
       }
     }

    // --- Construcción del Scaffold ---
    return Scaffold(
       appBar: AppBar( title: Text('Torneo (${provider.participantCount} Jugadores)'), actions: [ /*...*/ IconButton( icon: const Icon(Icons.undo), tooltip: 'Deshacer', onPressed: provider.canUndo ? () { _playClickSound(); context.read<TournamentProvider>().undoLastSelection(); } : null, ), IconButton( icon: const Icon(Icons.refresh), tooltip: 'Reiniciar', onPressed: _resetTournament, ), ], leading: IconButton( icon: const Icon(Icons.arrow_back), tooltip: 'Salir', onPressed: _goBack, ), ),
       body: Container( decoration: BoxDecoration( image: DecorationImage( image: const AssetImage('assets/images/tournament_bg.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode( Colors.black.withOpacity(0.7), BlendMode.darken,), ),),
         child: InteractiveViewer(
           transformationController: _transformationController,
           minScale: 0.05, maxScale: 5.0, constrained: false, boundaryMargin: const EdgeInsets.all(200.0),
           // Usar las dimensiones recalculadas para el SizedBox
           child: SizedBox(
             width: currentTotalWidth, // <-- Usar ancho recalculado
             height: currentTotalHeight, // <-- Usar alto recalculado
             child: Stack( children: stackChildren ),
           ),
         ),
       ),
       floatingActionButton: FloatingActionButton( mini: true, tooltip: 'Centrar Vista', onPressed: () { if (kDebugMode) print("Resetting view transformation."); _transformationController.value = Matrix4.identity(); }, child: const Icon(Icons.center_focus_strong), ),
    );
  }
}

// Clase BracketLinesPainter (CORREGIDA para Izq/Der -> Centro)
class BracketLinesPainter extends CustomPainter {
  final List<List<Match>> rounds; final Map<String, Offset> positions; final double matchHeight; final double matchWidth; final double hSpacing; final Paint linePaint;
  BracketLinesPainter({ required this.rounds, required this.positions, required this.matchHeight, required this.matchWidth, required this.hSpacing, }) : linePaint = Paint() ..color = Colors.grey[600]! ..strokeWidth = 1.5 ..style = PaintingStyle.stroke;
  @override void paint(Canvas canvas, Size size) { if (rounds.isEmpty || positions.isEmpty) return; final int totalRounds = rounds.length; for (int r = 0; r < totalRounds - 1; r++) { int matchesInThisRound = rounds[r].length; if(matchesInThisRound == 0) continue; int matchesOnLeft = (matchesInThisRound / 2).floor(); for (int m = 0; m < matchesInThisRound; m++) { if (m >= rounds[r].length) continue; final Match currentMatch = rounds[r][m]; final Offset? currentPos = positions[currentMatch.id]; if (currentPos == null) { if(kDebugMode) print("LinesPainter: Skip R:$r M:$m - No currentPos"); continue; } int nextMatchIndex = (m / 2).floor(); if (r + 1 < totalRounds && nextMatchIndex < rounds[r + 1].length) { final Match nextMatch = rounds[r + 1][nextMatchIndex]; final Offset? nextPos = positions[nextMatch.id]; if (nextPos == null) { if(kDebugMode) print("LinesPainter: Skip R:$r M:$m - No nextPos for R:${r+1} M:$nextMatchIndex"); continue; } bool isLeftBranch = m < matchesOnLeft; final Path path = Path(); double midX; Offset outPoint; Offset inPoint; bool connectingToFinal = (r == totalRounds - 2); if (isLeftBranch) { outPoint = Offset(currentPos.dx + matchWidth, currentPos.dy + matchHeight / 2); inPoint = Offset(nextPos.dx, nextPos.dy + matchHeight / 2); path.moveTo(outPoint.dx, outPoint.dy); if (connectingToFinal) { path.lineTo(inPoint.dx, outPoint.dy); path.lineTo(inPoint.dx, inPoint.dy); } else { midX = outPoint.dx + hSpacing / 2; path.lineTo(midX, outPoint.dy); path.lineTo(midX, inPoint.dy); path.lineTo(inPoint.dx, inPoint.dy); } } else { outPoint = Offset(currentPos.dx, currentPos.dy + matchHeight / 2); inPoint = Offset(nextPos.dx + matchWidth, nextPos.dy + matchHeight / 2); path.moveTo(outPoint.dx, outPoint.dy); if (connectingToFinal) { path.lineTo(inPoint.dx, outPoint.dy); path.lineTo(inPoint.dx, inPoint.dy); } else { midX = outPoint.dx - hSpacing / 2; path.lineTo(midX, outPoint.dy); path.lineTo(midX, inPoint.dy); path.lineTo(inPoint.dx, inPoint.dy); } } canvas.drawPath(path, linePaint); } } } }
  @override bool shouldRepaint(covariant BracketLinesPainter oldDelegate) { return oldDelegate.positions != positions || oldDelegate.rounds != rounds || oldDelegate.matchHeight != matchHeight || oldDelegate.matchWidth != matchWidth || oldDelegate.hSpacing != hSpacing; }
}
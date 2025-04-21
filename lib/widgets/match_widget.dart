import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../models/participant.dart';
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

/// Widget interactivo que muestra un partido individual del torneo.
class MatchWidget extends StatelessWidget {
  final Match match;
  final double nameFontSize;
  // Ya NO necesita recibir widgetWidth

  const MatchWidget({
    super.key,
    required this.match,
    this.nameFontSize = 12.0,
  });

  /// Llama al provider para seleccionar el ganador del partido.
  void _selectWinner(BuildContext context, Participant? potentialWinner) {
    if (potentialWinner == null) return;
    final provider = context.read<TournamentProvider>();
    if (kDebugMode) { print("[MatchWidget] Intento de seleccionar ganador:"); print("  > Partido ID: ${match.id} (R${match.roundIndex} M${match.matchIndexInRound})"); print("  > Ganador Potencial: ${potentialWinner.name} (ID: ${potentialWinner.id})"); print("  > Condiciones: Torneo Activo=${provider.isTournamentActive}, Partido Listo=${match.isReadyToPlay}, Partido Terminado=${match.isFinished}"); }
    if (provider.isTournamentActive && match.isReadyToPlay && !match.isFinished) {
      if (kDebugMode) print("[MatchWidget] ¡Condiciones OK para ${match.id}! Llamando a provider.selectWinner...");
      AudioManager.instance.playClickSound();
      provider.selectWinner(match.id, potentialWinner.id);
      final bool tournamentHasJustFinished = context.read<TournamentProvider>().isTournamentFinished;
      if (!tournamentHasJustFinished) { AudioManager.instance.playWinMatchSound(); }
      else { if (kDebugMode) print("[MatchWidget] La selección finalizó el torneo..."); }
    } else { if (kDebugMode) print("[MatchWidget] Condiciones NO OK para ${match.id}. Selección ignorada."); }
  }

  @override
  Widget build(BuildContext context) {
    // --- Obtener datos y calcular estilos ---
    final p1 = match.participant1; final p2 = match.participant2; final winner = match.winner;
    final bool isP1Winner = winner != null && p1 != null && winner.id == p1.id;
    final bool isP2Winner = winner != null && p2 != null && winner.id == p2.id;
    final bool canPlay = context.select((TournamentProvider p) => p.isTournamentActive) && match.isReadyToPlay && !match.isFinished;
    final baseStyle = TextStyle(fontSize: nameFontSize, color: Colors.white);
    final winnerStyle = baseStyle.copyWith( fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary);
    final loserStyle = baseStyle.copyWith( color: Colors.grey[600], decoration: TextDecoration.lineThrough);
    final tbdStyle = baseStyle.copyWith( color: Colors.grey[500], fontStyle: FontStyle.italic);
    TextStyle p1Style; TextStyle p2Style;
    if (match.isFinished) { p1Style = isP1Winner ? winnerStyle : (p1 == null ? tbdStyle : loserStyle); p2Style = isP2Winner ? winnerStyle : (p2 == null ? tbdStyle : loserStyle); }
    else { p1Style = p1 == null ? tbdStyle : baseStyle; p2Style = p2 == null ? tbdStyle : baseStyle; }

    // --- Widget UI (CON Container exterior) ---
    return Container(
      // El tamaño lo da MatchSlot
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      decoration: BoxDecoration(
        color: Colors.grey[850], // Restaurado
        borderRadius: BorderRadius.circular(6.0), // Restaurado
        border: Border.all( color: canPlay ? Colors.indigo[300]! : Colors.grey[700]!, width: 1.0, ), // Restaurado
        boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(1, 1), ) ], // Restaurado
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuir si hay espacio extra
        children: [
          // Usar la versión de _buildParticipantRow que evita RenderFlex
          _buildParticipantRow( context: context, participant: p1, style: p1Style, isWinner: isP1Winner, onTap: canPlay && p1 != null ? () => _selectWinner(context, p1) : null, ),
          const Divider(height: 1, thickness: 0.5, color: Colors.grey),
          _buildParticipantRow( context: context, participant: p2, style: p2Style, isWinner: isP2Winner, onTap: canPlay && p2 != null ? () => _selectWinner(context, p2) : null, ),
        ],
      ),
    );
  }

  /// Construye la fila para un participante (SIN Flexible/Expanded/Spacer, CON spaceBetween)
  Widget _buildParticipantRow({ required BuildContext context, required Participant? participant, required TextStyle style, required bool isWinner, required VoidCallback? onTap, }) {
    const double iconSize = 14.0;
    const double iconSpacing = 4.0;
    bool showTapIcon = (onTap != null);

    return InkWell( onTap: onTap, splashColor: onTap != null ? Theme.of(context).colorScheme.secondary.withOpacity(0.3) : Colors.transparent, highlightColor: onTap != null ? Theme.of(context).colorScheme.secondary.withOpacity(0.1) : Colors.transparent,
      child: Container( padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Usar spaceBetween
          children: [
            // Agrupar icono de ganador y nombre juntos
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 if (isWinner) Icon(Icons.star, color: Theme.of(context).colorScheme.secondary, size: iconSize),
                 if (isWinner) const SizedBox(width: iconSpacing),
                 // Texto simple con ellipsis
                 Text( participant?.name ?? 'Por determinar', style: style, overflow: TextOverflow.ellipsis, maxLines: 1, ),
              ],
            ),
            // Icono de "tocar" (si aplica), quedará a la derecha por spaceBetween
            if (showTapIcon) Icon(Icons.touch_app_outlined, size: iconSize, color: Colors.grey[600]),
          ],
        ),
      ),
    );
 }
}
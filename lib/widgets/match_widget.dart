// En lib/widgets/match_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../models/participant.dart';
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart'; // Para sonidos

class MatchWidget extends StatelessWidget {
  final Match match;
  final double nameFontSize; // Hacer tamaño de fuente configurable
  final double widgetWidth; // Ancho opcional

  const MatchWidget({
    super.key,
    required this.match,
    this.nameFontSize = 12.0, // Tamaño por defecto
    this.widgetWidth = 150.0 // Ancho por defecto
  });

  // --- MÉTODO ACTUALIZADO ---
  void _selectWinner(BuildContext context, Participant? potentialWinner) {
      if (potentialWinner == null) return; // No hacer nada si se clickea en TBD

      final provider = context.read<TournamentProvider>();
      // Verificar si el partido se puede jugar y el torneo está activo
      if (provider.isTournamentActive && match.isReadyToPlay && !match.isFinished) {

          // 1. Reproducir sonido de clic
          AudioManager.instance.playClickSound();

          // 2. Actualizar el estado del torneo (seleccionar ganador)
          provider.selectWinner(match.id, potentialWinner.id);

          // 3. Verificar el estado del torneo DESPUÉS de actualizarlo
          final bool tournamentHasJustFinished = provider.isTournamentFinished;

          // 4. Reproducir 'win_match' SÓLO si el torneo NO acaba de terminar
          if (!tournamentHasJustFinished) {
            AudioManager.instance.playWinMatchSound();
          }
          // Si tournamentHasJustFinished es true, el listener en TournamentScreen
          // se encargará de reproducir 'win_tournament.ogg' y navegar.
      }
  }
  // --- FIN DEL MÉTODO ACTUALIZADO ---


  @override
  Widget build(BuildContext context) {
    final participant1 = match.participant1;
    final participant2 = match.participant2;
    final winner = match.winner;
    final bool isP1Winner = winner != null && winner.id == participant1?.id;
    final bool isP2Winner = winner != null && winner.id == participant2?.id;

    // Determinar si el partido puede ser jugado
    final bool canPlay = context.select((TournamentProvider p) => p.isTournamentActive)
                       && match.isReadyToPlay && !match.isFinished;


    // Estilo base para los nombres
    final baseStyle = TextStyle(fontSize: nameFontSize, color: Colors.white);
    // Estilo para el ganador
    final winnerStyle = baseStyle.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary);
     // Estilo para el perdedor (opcional)
    final loserStyle = baseStyle.copyWith(color: Colors.grey[600], decoration: TextDecoration.lineThrough);
     // Estilo para 'TBD'
     final tbdStyle = baseStyle.copyWith(color: Colors.grey[500], fontStyle: FontStyle.italic);

    return Container(
      width: widgetWidth,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0), // Espacio entre widgets de partido
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: canPlay ? Colors.indigo[300]! : Colors.grey[700]!, // Borde diferente si está jugable
          width: 1.0,
        ),
         boxShadow: [ // Sombra sutil
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(1, 1),
            ),
          ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ajustar al contenido
        children: [
          // --- Participante 1 ---
          _buildParticipantRow(
            context: context,
            participant: participant1,
            style: match.isFinished
                   ? (isP1Winner ? winnerStyle : loserStyle)
                   : (participant1 == null ? tbdStyle : baseStyle),
            isWinner: isP1Winner,
            onTap: canPlay ? () => _selectWinner(context, participant1) : null,
          ),

          const Divider(height: 4, thickness: 1, color: Colors.grey), // Separador

          // --- Participante 2 ---
           _buildParticipantRow(
            context: context,
            participant: participant2,
            style: match.isFinished
                   ? (isP2Winner ? winnerStyle : loserStyle)
                   : (participant2 == null ? tbdStyle : baseStyle),
            isWinner: isP2Winner,
            onTap: canPlay ? () => _selectWinner(context, participant2) : null,
          ),
        ],
      ),
    );
  }

  // Widget helper para mostrar la fila de un participante
  Widget _buildParticipantRow({
    required BuildContext context,
    required Participant? participant,
    required TextStyle style,
    required bool isWinner,
    required VoidCallback? onTap,
  }) {
    return InkWell( // Para hacer clickeable toda la fila
       onTap: onTap,
       splashColor: onTap != null ? Theme.of(context).colorScheme.secondary.withOpacity(0.3) : Colors.transparent,
       highlightColor: onTap != null ? Theme.of(context).colorScheme.secondary.withOpacity(0.1) : Colors.transparent,
      child: Container( // Container para padding interno
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
             // Icono de ganador (opcional)
            if (isWinner)
              Icon(Icons.star, color: Theme.of(context).colorScheme.secondary, size: nameFontSize + 2),
            if (isWinner) const SizedBox(width: 4),

            Expanded(
              child: Text(
                participant?.name ?? 'Por determinar',
                style: style,
                overflow: TextOverflow.ellipsis, // Evitar overflow de texto largo
              ),
            ),
            // Indicador de clickeable (opcional)
             if (onTap != null)
               Icon(Icons.touch_app_outlined, size: nameFontSize + 2, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
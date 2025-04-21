import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Quitar import de GoogleFonts si ya no se usa directamente aquí
// import 'package:google_fonts/google_fonts.dart';
import '../models/match.dart';
import '../models/participant.dart';
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

/// Widget interactivo que muestra un partido individual del torneo.
/// Versión con Estética Mejorada v1.
class MatchWidget extends StatelessWidget {
  final Match match;
  // Tamaño base de la fuente para los nombres de participantes
  final double nameFontSize;

  const MatchWidget({
    super.key,
    required this.match,
    this.nameFontSize = 14.0, // <-- Tamaño base aumentado
  });

  /// Llama al provider para seleccionar el ganador del partido.
  void _selectWinner(BuildContext context, Participant? potentialWinner) {
    // ... (Lógica interna sin cambios) ...
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
    // Obtener referencias al tema actual para usar sus colores y fuentes
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- Calcular estados y estilos ---
    final p1 = match.participant1; final p2 = match.participant2; final winner = match.winner;
    final bool isP1Winner = winner != null && p1 != null && winner.id == p1.id;
    final bool isP2Winner = winner != null && p2 != null && winner.id == p2.id;
    final bool canPlay = context.select((TournamentProvider p) => p.isTournamentActive) && match.isReadyToPlay && !match.isFinished;

    // Estilos basados en el tema y estado
    final baseStyle = textTheme.bodyMedium?.copyWith(fontSize: nameFontSize, color: colorScheme.onSurfaceVariant) ?? TextStyle(fontSize: nameFontSize, color: Colors.white); // Usar color sobre surfaceVariant
    final winnerStyle = baseStyle.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary); // Ganador en ámbar
    final loserStyle = baseStyle.copyWith(color: colorScheme.outline, decoration: TextDecoration.lineThrough); // Perdedor con color outline
    final tbdStyle = baseStyle.copyWith(color: colorScheme.outlineVariant, fontStyle: FontStyle.italic); // TBD con color outlineVariant

    TextStyle p1Style; TextStyle p2Style;
    if (match.isFinished) { p1Style = isP1Winner ? winnerStyle : (p1 == null ? tbdStyle : loserStyle); p2Style = isP2Winner ? winnerStyle : (p2 == null ? tbdStyle : loserStyle); }
    else { p1Style = p1 == null ? tbdStyle : baseStyle; p2Style = p2 == null ? tbdStyle : baseStyle; }

    // --- Construcción del Widget ---
    return Container(
      // Tamaño viene del MatchSlot padre (usa kMatchWidth, kMatchHeight)
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0), // Padding interno ajustado
      decoration: BoxDecoration(
        // Fondo: Color 'surfaceVariant' del tema con opacidad
        color: colorScheme.surfaceVariant.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10.0), // Bordes más redondeados
        border: Border.all(
          // Color: Secundario (ámbar) si se puede jugar, si no 'outlineVariant'
          color: canPlay ? colorScheme.secondary : colorScheme.outlineVariant,
          // Grosor: Más grueso si se puede jugar
          width: canPlay? 1.8 : 1.2,
        ),
         boxShadow: [ // Sombra suave
          BoxShadow( color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(1, 2), )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente el contenido
        children: [
          _buildParticipantRow( context: context, participant: p1, style: p1Style, isWinner: isP1Winner, onTap: canPlay && p1 != null ? () => _selectWinner(context, p1) : null, ),
          // Divisor más sutil usando color del tema
          Divider(height: 1, thickness: 0.5, color: theme.dividerColor.withOpacity(0.5)),
          _buildParticipantRow( context: context, participant: p2, style: p2Style, isWinner: isP2Winner, onTap: canPlay && p2 != null ? () => _selectWinner(context, p2) : null, ),
        ],
      ),
    );
  }

  /// Construye la fila para un participante.
  Widget _buildParticipantRow({ required BuildContext context, required Participant? participant, required TextStyle style, required bool isWinner, required VoidCallback? onTap }) {
    const double iconSize = 16.0; // Iconos ligeramente más grandes
    const double iconSpacing = 5.0;
    bool showTapIcon = (onTap != null);
    final colorScheme = Theme.of(context).colorScheme; // Usar colores del tema

    return InkWell( onTap: onTap, splashColor: onTap != null ? colorScheme.secondary.withOpacity(0.3) : Colors.transparent, highlightColor: onTap != null ? colorScheme.secondary.withOpacity(0.1) : Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7.0), // Un poco más de padding vertical
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mantiene separación
          children: [
            // Grupo Izquierda: Icono (opcional) + Nombre
            Row(
              mainAxisSize: MainAxisSize.min, // Evita que ocupe espacio extra
              children: [
                 if (isWinner) Icon(Icons.star, color: colorScheme.secondary, size: iconSize), // Icono estrella
                 if (isWinner) const SizedBox(width: iconSpacing),
                 // Nombre con ellipsis
                 Text( participant?.name ?? 'Por determinar', style: style, overflow: TextOverflow.ellipsis, maxLines: 1, ),
              ],
            ),
            // Icono Derecha: Tocar (si aplica)
            if (showTapIcon) Icon(Icons.touch_app, size: iconSize, color: colorScheme.outline), // Icono y color de tema
          ],
        ),
      ),
    );
 }
}
import 'participant.dart';

class Match {
  final String id; // Usaremos UUID
  Participant? participant1;
  Participant? participant2;
  String? winnerId; // ID del participante ganador
  final int roundIndex; // Índice de la ronda (0, 1, 2...)
  final int matchIndexInRound; // Índice del partido dentro de su ronda

  Match({
    required this.id,
    this.participant1,
    this.participant2,
    this.winnerId,
    required this.roundIndex,
    required this.matchIndexInRound,
  });

  Participant? get winner {
      if (winnerId == null) return null;
      if (participant1?.id == winnerId) return participant1;
      if (participant2?.id == winnerId) return participant2;
      return null; // No debería pasar si winnerId está bien asignado
  }

  bool get isFinished => winnerId != null;
  // Un partido está listo para jugarse si tiene ambos participantes
  bool get isReadyToPlay => participant1 != null && participant2 != null;
  // Un partido está esperando un participante (uno ya avanzó)
  bool get isWaitingForParticipant => (participant1 != null && participant2 == null) || (participant1 == null && participant2 != null);

  @override
  String toString() {
    String p1Name = participant1?.name ?? 'TBD';
    String p2Name = participant2?.name ?? 'TBD';
    String winName = winner?.name ?? 'None';
    return 'Match{id: $id, R:$roundIndex, M:$matchIndexInRound, $p1Name vs $p2Name, Winner: $winName}';
  }
}
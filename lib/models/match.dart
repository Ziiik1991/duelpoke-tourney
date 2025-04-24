import 'participant.dart';

/// Representa un partido individual dentro de una ronda del torneo.
class Match {
  final String id;
  Participant? participant1;
  Participant? participant2;
  String? winnerId;
  final int roundIndex;
  final int matchIndexInRound;

  // Mapa estático temporal para buscar participantes por ID al cargar desde JSON
  static Map<String, Participant> _participantLookup = {};

  /// Establece el mapa de búsqueda antes de deserializar partidos.
  static void setParticipantLookup(Map<String, Participant> lookup) {
    _participantLookup = lookup;
  }

  Match({
    required this.id,
    this.participant1,
    this.participant2,
    this.winnerId,
    required this.roundIndex,
    required this.matchIndexInRound,
  });

  /// Devuelve el objeto Participant ganador (o null).
  Participant? get winner {
    if (winnerId == null) return null;
    // Busca primero entre los participantes directos del partido
    if (participant1?.id == winnerId) return participant1;
    if (participant2?.id == winnerId) return participant2;
    // Si no, intenta buscar en el mapa global
    return _participantLookup[winnerId];
  }

  /// Indica si el partido ya tiene un ganador asignado.
  bool get isFinished => winnerId != null;

  /// Indica si ambos participantes están definidos y listos para jugar.
  bool get isReadyToPlay => participant1 != null && participant2 != null;

  /// Indica si este slot es un BYE (tiene ganador pero falta un participante).
  bool get isBye =>
      winnerId != null &&
      (participant1 == null ||
          participant2 == null ||
          participant1?.id == winnerId ||
          participant2?.id == winnerId);

  @override
  String toString() {
    String p1N = participant1?.name ?? 'TBD';
    String p2N = participant2?.name ?? 'TBD';
    String wN = winner?.name ?? 'None';
    return 'Match{id:$id,R:$roundIndex,M:$matchIndexInRound,$p1N vs $p2N,W:$wN}';
  }

  // --- JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'p1Id': participant1?.id,
      'p2Id': participant2?.id,
      'winnerId': winnerId,
      'roundIndex': roundIndex,
      'matchIndexInRound': matchIndexInRound,
    };
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    final p1Id = json['p1Id'] as String?;
    final p2Id = json['p2Id'] as String?;
    final winnerIdFromJson = json['winnerId'] as String?;

    // Usar el mapa temporal para encontrar los objetos Participant
    final p1 = p1Id != null ? _participantLookup[p1Id] : null;
    final p2 = p2Id != null ? _participantLookup[p2Id] : null;

    return Match(
      id: json['id'] as String? ?? '',
      participant1: p1,
      participant2: p2,
      winnerId: winnerIdFromJson,
      roundIndex: json['roundIndex'] as int? ?? -1,
      matchIndexInRound: json['matchIndexInRound'] as int? ?? -1,
    );
  }
  // --- Fin JSON Serialization ---
}

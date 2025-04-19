// lib/models/match.dart
import 'participant.dart'; // Importa el modelo correcto

class Match {
  final String id;
  Participant? participant1;
  Participant? participant2;
  String? winnerId;
  final int roundIndex;
  final int matchIndexInRound;

  Match({
    required this.id,
    this.participant1,
    this.participant2,
    this.winnerId,
    required this.roundIndex,
    required this.matchIndexInRound,
  });

  Participant? get winner { /* ... código getter ... */ if(winnerId==null)return null;if(participant1?.id==winnerId)return participant1;if(participant2?.id==winnerId)return participant2;return null; }
  bool get isFinished => winnerId != null;
  bool get isReadyToPlay => participant1 != null && participant2 != null;
  // ---> GETTER isBye <---
  bool get isBye => winnerId != null && (participant1 == null || participant2 == null);
  // ---> FIN GETTER isBye <---

  @override
  String toString() { /* ... código toString ... */ String p1N=participant1?.name??'TBD';String p2N=participant2?.name??'TBD';String wN=winner?.name??'None';return 'Match{id:$id,R:$roundIndex,M:$matchIndexInRound,$p1N vs $p2N,W:$wN}'; }
}
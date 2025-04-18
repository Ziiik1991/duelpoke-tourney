import 'dart:math'; // Para shuffle y log
import 'package:flutter/foundation.dart';
import '../models/participant.dart';
import '../models/match.dart';
import 'package:uuid/uuid.dart';

class TournamentProvider with ChangeNotifier {
  final _uuid = const Uuid();

  List<Participant> _participants = [];
  List<List<Match>> _rounds = []; // Lista de rondas, cada ronda es una lista de partidos
  Participant? _winner;
  bool _isTournamentActive = false;
  String? _tournamentError;

  // --- Getters ---
  List<Participant> get participants => List.unmodifiable(_participants);
  List<List<Match>> get rounds => List.unmodifiable(_rounds);
  Participant? get winner => _winner;
  bool get isTournamentActive => _isTournamentActive;
  bool get isTournamentFinished => _winner != null;
  String? get tournamentError => _tournamentError;
  int get participantCount => _participants.length;


  // --- Métodos Gestión Participantes ---
  void addParticipant(String name) {
    _tournamentError = null;
    name = name.trim();
    if (name.isEmpty) {
      _setError("El nombre no puede estar vacío.");
      return;
    }
    if (_participants.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      _setError("'$name' ya está registrado.");
      return;
    }
    // Permitimos hasta 16, aunque solo visualicemos bien 2, 4, 16 por ahora
    if (_participants.length >= 16) {
       _setError("Máximo 16 participantes alcanzado.");
      return;
    }

    final newParticipant = Participant(id: _uuid.v4(), name: name);
    _participants.add(newParticipant);
    if (kDebugMode) print("Participante Añadido: ${newParticipant.name}");
    notifyListeners();
  }

  void removeParticipant(String id) {
    _tournamentError = null;
    _participants.removeWhere((p) => p.id == id);
     if (kDebugMode) print("Participante Eliminado ID: $id");
    notifyListeners();
  }

  void _setError(String message) {
     _tournamentError = message;
     notifyListeners();
  }

  void clearError() {
    if (_tournamentError != null) {
        _tournamentError = null;
        notifyListeners();
    }
  }

  // --- Métodos Gestión Torneo ---
  bool canStartTournament() {
    final count = _participants.length;
    // Permitimos 8 aunque la UI no esté lista, la lógica sí funcionará
    return count == 2 || count == 4 || count == 8 || count == 16;
  }

  void startTournament() {
    if (!canStartTournament()) {
      _setError("Se necesitan 2, 4, 8 o 16 participantes para iniciar.");
      return;
    }
    _tournamentError = null;
    _winner = null;
    _rounds = _generateBracket(_participants);
    _isTournamentActive = true;
     if (kDebugMode) print("Torneo iniciado con ${_participants.length} participantes.");
    notifyListeners();
  }

  List<List<Match>> _generateBracket(List<Participant> initialParticipants) {
     List<List<Match>> generatedRounds = [];
     if (initialParticipants.isEmpty) return generatedRounds;

     List<Participant> currentRoundParticipants = List.from(initialParticipants)..shuffle(Random());
     int numRounds = (log(initialParticipants.length) / log(2)).ceil(); // Calcular número de rondas
     int roundIdx = 0;

     // Generar primera ronda con participantes
     List<Match> firstRoundMatches = [];
     for (int i = 0; i < currentRoundParticipants.length; i += 2) {
         firstRoundMatches.add(Match(
             id: _uuid.v4(),
             participant1: currentRoundParticipants[i],
             participant2: currentRoundParticipants[i + 1], // Asume siempre número par (2, 4, 8, 16)
             roundIndex: roundIdx,
             matchIndexInRound: i ~/ 2,
         ));
     }
     generatedRounds.add(firstRoundMatches);
     roundIdx++;

     // Generar rondas subsiguientes (vacías)
     int matchesInPreviousRound = firstRoundMatches.length;
     while (roundIdx < numRounds) {
         List<Match> nextRoundMatches = [];
         int matchesInThisRound = (matchesInPreviousRound / 2).ceil();
         for (int i = 0; i < matchesInThisRound; i++) {
             nextRoundMatches.add(Match(
                 id: _uuid.v4(),
                 roundIndex: roundIdx,
                 matchIndexInRound: i,
                 // participant1 y participant2 serán null inicialmente
             ));
         }
         generatedRounds.add(nextRoundMatches);
         matchesInPreviousRound = matchesInThisRound;
         roundIdx++;
     }

     if (kDebugMode) print("Bracket generado: ${generatedRounds.length} rondas.");
     return generatedRounds;
 }


 void selectWinner(String matchId, String winnerParticipantId) {
    if (!_isTournamentActive || isTournamentFinished) return;
     if (kDebugMode) print("Intentando seleccionar ganador para Match $matchId: Participante $winnerParticipantId");

    Match? targetMatch;
    int currentRoundIndex = -1;
    int currentMatchIndex = -1;

    // 1. Encontrar el partido
    for (int r = 0; r < _rounds.length; r++) {
        for (int m = 0; m < _rounds[r].length; m++) {
            if (_rounds[r][m].id == matchId) {
                targetMatch = _rounds[r][m];
                currentRoundIndex = r;
                currentMatchIndex = m;
                break;
            }
        }
        if (targetMatch != null) break;
    }


    if (targetMatch == null || targetMatch.isFinished) {
         if (kDebugMode) print("Error: Partido no encontrado o ya finalizado.");
        return; // Partido no encontrado o ya terminado
    }

    // 2. Actualizar el ganador del partido actual
    targetMatch.winnerId = winnerParticipantId;
    Participant? winnerParticipant = targetMatch.winner; // Obtener el objeto Participant

     if (kDebugMode) print("Partido R:$currentRoundIndex M:$currentMatchIndex actualizado. Ganador: ${winnerParticipant?.name}");


    // 3. Avanzar al ganador a la siguiente ronda (si no es la ronda final)
    bool isFinalRound = currentRoundIndex == _rounds.length - 1;

    if (!isFinalRound && winnerParticipant != null) {
      int nextRoundIndex = currentRoundIndex + 1;
      // El índice del partido en la siguiente ronda es la mitad del índice actual (redondeado hacia abajo)
      int nextMatchIndex = (currentMatchIndex / 2).floor();

      // Asegurarse de que la siguiente ronda y partido existan
      if (nextRoundIndex < _rounds.length && nextMatchIndex < _rounds[nextRoundIndex].length) {
        Match nextMatch = _rounds[nextRoundIndex][nextMatchIndex];

        // Asignar al participante en la ranura correcta (par o impar)
        if (currentMatchIndex % 2 == 0) {
          // Si el índice actual es par, va a participant1 del siguiente partido
          nextMatch.participant1 = winnerParticipant;
           if (kDebugMode) print("Avanzando ${winnerParticipant.name} a R:$nextRoundIndex M:$nextMatchIndex como P1");
        } else {
          // Si el índice actual es impar, va a participant2 del siguiente partido
          nextMatch.participant2 = winnerParticipant;
           if (kDebugMode) print("Avanzando ${winnerParticipant.name} a R:$nextRoundIndex M:$nextMatchIndex como P2");
        }
      } else {
          if (kDebugMode) print("Error: No se encontró el siguiente partido R:$nextRoundIndex M:$nextMatchIndex");
      }
    } else if (isFinalRound && winnerParticipant != null) {
      // 4. Si es la ronda final, determinar el campeón del torneo
      _winner = winnerParticipant;
      _isTournamentActive = false; // El torneo ya no está activo, está terminado
       if (kDebugMode) print("¡Torneo finalizado! Campeón: ${_winner?.name}");
    }

    notifyListeners(); // Notificar a la UI sobre todos los cambios
  }


  void resetTournament() {
    _participants = [];
    _rounds = [];
    _winner = null;
    _isTournamentActive = false;
    _tournamentError = null;
     if (kDebugMode) print("Torneo reseteado.");
    notifyListeners();
  }
}
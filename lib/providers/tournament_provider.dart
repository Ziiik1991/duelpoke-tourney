import 'dart:math';
import 'package:flutter/foundation.dart'; // Necesario para kDebugMode
import '../models/participant.dart';
import '../models/match.dart';
import 'package:uuid/uuid.dart';
// Quitar si no se usan
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

class TournamentProvider with ChangeNotifier {
  final _uuid = const Uuid();
  List<Participant> _participants = [];
  List<List<Match>> _rounds = [];
  Participant? _winner;
  bool _isTournamentActive = false;
  String? _tournamentError;

  // --- Estado para Deshacer ---
  String? _lastAffectedMatchId;
  String? _lastAdvancedToMatchId;
  Participant? _lastWinner;
  // _originalOpponent eliminado
  bool _wasLastAdvanceToP1 = false;
  bool _canUndo = false;

  // --- Getters ---
  List<Participant> get participants => List.unmodifiable(_participants);
  List<List<Match>> get rounds => List.unmodifiable(_rounds);
  Participant? get winner => _winner;
  bool get isTournamentActive => _isTournamentActive;
  bool get isTournamentFinished => _winner != null;
  String? get tournamentError => _tournamentError;
  int get participantCount => _participants.length;
  bool get canUndo => _canUndo;

  // --- Métodos ---
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
    // --- LÍMITE CAMBIADO A 32 ---
    if (_participants.length >= 32) {
      _setError("Máximo 32 participantes alcanzado."); // Mensaje actualizado
      return;
    }
    final newParticipant = Participant(id: _uuid.v4(), name: name);
    _participants.add(newParticipant);
     if (kDebugMode) print("Participante Añadido: ${newParticipant.name}");
    notifyListeners();
  }

  void removeParticipant(String id) {
    _tournamentError = null;
    final participantIndex = _participants.indexWhere((p) => p.id == id);
     if (participantIndex != -1) {
         if (kDebugMode) print("Participante Eliminado: ${_participants[participantIndex].name} (ID: $id)");
         _participants.removeAt(participantIndex);
         notifyListeners();
     } else {
          if (kDebugMode) print("Error: No se encontró participante para eliminar con ID: $id");
     }
  }

  void _setError(String message) {
    _tournamentError = message;
     if (kDebugMode) print("Error Establecido: $message");
    notifyListeners();
  }

  void clearError() {
    if (_tournamentError != null) {
      _tournamentError = null;
      notifyListeners();
    }
  }

  bool canStartTournament() {
    final count = _participants.length;
    // --- LÍMITE CAMBIADO A 32 ---
    return count >= 3 && count <= 32;
  }

  void startTournament() {
    if (!canStartTournament()) {
      // --- MENSAJE DE ERROR ACTUALIZADO ---
      _setError("Se necesitan entre 3 y 32 participantes para iniciar.");
      notifyListeners();
      return;
    }
    _tournamentError = null;
    _winner = null;
    _rounds = _generateBracket(_participants);
    _isTournamentActive = true;
    _canUndo = false;
    _clearUndoState();
     if (kDebugMode) {
         print("Torneo iniciado con ${_participants.length} participantes.");
         _printDebugBracket();
     }
    notifyListeners();
  }

  List<List<Match>> _generateBracket(List<Participant> initialParticipants) {
      if (initialParticipants.isEmpty) return [];
      final int nP = initialParticipants.length;
      if (nP < 2) return [];
      final int nP2 = pow(2, (log(nP) / log(2)).ceil()).toInt();
      final int nR = (log(nP2) / log(2)).toInt();
      final int nMR0 = nP2 ~/ 2;
      final int nB = nP2 - nP;
      final int nFP = nP - nB;
      final int nMA0 = nFP ~/ 2;

       if (kDebugMode) {
          print("Generando bracket V7 para $nP participantes.");
          print("Tamaño virtual: $nP2, Rondas: $nR");
          print("BYEs: $nB, Partidos Reales R0: $nMA0");
      }

      List<Participant> shuffledParticipants = List.from(initialParticipants)..shuffle(Random());
      List<Participant> byeParticipants = shuffledParticipants.sublist(0, nB);
      List<Participant> playingParticipants = shuffledParticipants.sublist(nB);
      List<List<Match>> generatedRounds = List.generate(nR, (r) {
          int matchesInRound = nP2 ~/ pow(2, r + 1);
           if (kDebugMode) print("Ronda $r: Creando ${matchesInRound} slots.");
          return List.generate(matchesInRound, (m) => Match( id: _uuid.v4(), roundIndex: r, matchIndexInRound: m, ));
      });
       if (kDebugMode) print("Estructura de rondas vacía creada.");

      int byeIndex = 0;
      int playerIndex = 0;
      int byesAssigned = 0;
      int realMatchesAssigned = 0;

      for (int m = 0; m < nMR0; m++) {
          Match currentMatch = generatedRounds[0][m];
          if (byesAssigned < nB) {
              if (byeIndex < byeParticipants.length) {
                  Participant byeWinner = byeParticipants[byeIndex++];
                  currentMatch.participant1 = byeWinner;
                  currentMatch.participant2 = null;
                  currentMatch.winnerId = byeWinner.id;
                  byesAssigned++;
                   if (kDebugMode) print("Asignando BYE a ${byeWinner.name} en R:0 M:$m");
                  if (nR > 1) {
                      int nextRoundIndex = 1;
                      int nextMatchIndex = (m / 2).floor();
                      if (nextRoundIndex < generatedRounds.length && nextMatchIndex < generatedRounds[nextRoundIndex].length) {
                          Match nextMatch = generatedRounds[nextRoundIndex][nextMatchIndex];
                          if (m % 2 == 0) {
                             nextMatch.participant1 = byeWinner;
                              if (kDebugMode) print("Avanzando BYE ${byeWinner.name} a R:1 M:$nextMatchIndex como P1");
                          } else {
                             nextMatch.participant2 = byeWinner;
                              if (kDebugMode) print("Avanzando BYE ${byeWinner.name} a R:1 M:$nextMatchIndex como P2");
                          }
                      } else {
                          if (kDebugMode) print("WARN: No se encontró el siguiente partido para avanzar BYE R:$nextRoundIndex M:$nextMatchIndex");
                      }
                  }
              } else {
                  if (kDebugMode) print("Error Lógico: Se esperaban más BYEs de los disponibles en R:0 M:$m");
              }
          } else if (realMatchesAssigned < nMA0) {
              int p1ListIndex = playerIndex;
              int p2ListIndex = playerIndex + 1;
              if (p2ListIndex < playingParticipants.length) {
                  Participant p1 = playingParticipants[p1ListIndex];
                  Participant p2 = playingParticipants[p2ListIndex];
                  currentMatch.participant1 = p1;
                  currentMatch.participant2 = p2;
                  currentMatch.winnerId = null;
                  realMatchesAssigned++;
                  playerIndex += 2;
                   if (kDebugMode) print("Asignando Partido ${p1.name} vs ${p2.name} en R:0 M:$m");
              } else {
                 if (kDebugMode) print("Error CRÍTICO: Número impar de jugadores restantes para asignar partidos en R:0 M:$m");
                 if(p1ListIndex < playingParticipants.length){
                    Participant p1 = playingParticipants[p1ListIndex];
                     currentMatch.participant1 = p1;
                     currentMatch.participant2 = null;
                     currentMatch.winnerId = p1.id;
                     realMatchesAssigned++;
                     playerIndex++;
                      if (kDebugMode) print("WARN: Jugador ${p1.name} sin pareja, asignado como BYE forzado.");
                 }
              }
          } else {
              if (kDebugMode) print("Info: Slot virtual R:0 M:$m sin uso.");
          }
      }
       if (kDebugMode) {
          int finalByeCount = generatedRounds[0].where((m) => m.isBye).length;
          int finalMatchCount = generatedRounds[0].where((m) => m.participant1 != null && m.participant2 != null && !m.isFinished).length;
          print("Ronda 0 populada: $finalByeCount BYEs procesados, $finalMatchCount partidos reales asignados.");
          if (finalByeCount != nB || finalMatchCount != nMA0) {
               print("WARN: Conteos finales ($finalByeCount B/$finalMatchCount M) != Esperados ($nB B/$nMA0 M)");
          }
           print("Bracket final generado con $nR rondas.");
      }
      return generatedRounds;
  }

  // --- selectWinner con prints de debug detallados ---
  void selectWinner(String matchId, String winnerParticipantId) {
    if (kDebugMode) print("[Provider] selectWinner ENTRY - MatchID: $matchId, WinnerID: $winnerParticipantId");
    if (!_isTournamentActive || isTournamentFinished) { if (kDebugMode) print("[Provider] selectWinner EXIT - Torneo no activo o ya finalizado."); return; }
    Match? targetMatch; int currentRoundIndex = -1; int currentMatchIndexInRound = -1;
    for (int r = 0; r < _rounds.length; r++) { for (int m = 0; m < _rounds[r].length; m++) { if (_rounds[r][m].id == matchId) { targetMatch = _rounds[r][m]; currentRoundIndex = r; currentMatchIndexInRound = m; break; } } if (targetMatch != null) break; }
    if (targetMatch == null) { if (kDebugMode) print("[Provider] selectWinner EXIT - Partido $matchId no encontrado."); return; }
    if (targetMatch.isFinished) { if (kDebugMode) print("[Provider] selectWinner EXIT - Partido ${targetMatch.id} ya finalizado."); return; }
    if (!targetMatch.isReadyToPlay) { if (kDebugMode) print("[Provider] selectWinner EXIT - Partido ${targetMatch.id} no listo (P1:${targetMatch.participant1?.name}, P2:${targetMatch.participant2?.name})."); return; }
    _clearUndoState(); _lastAffectedMatchId = targetMatch.id; _lastWinner = targetMatch.participant1?.id == winnerParticipantId ? targetMatch.participant1 : targetMatch.participant2;
    if (kDebugMode) print("[Provider] selectWinner - Found Match R:$currentRoundIndex M:$currentMatchIndexInRound. Assigning winner...");
    targetMatch.winnerId = winnerParticipantId; Participant? winnerParticipant = targetMatch.winner;
    bool isFinalRound = currentRoundIndex == _rounds.length - 1;
    if (kDebugMode) print("[Provider] selectWinner - Check conditions: isFinalRound: $isFinalRound, winnerParticipant exists: ${winnerParticipant != null}");
    if (!isFinalRound && winnerParticipant != null) {
      int nextRoundIndex = currentRoundIndex + 1; int nextMatchIndex = (currentMatchIndexInRound / 2).floor();
       if (kDebugMode) print("[Provider] selectWinner - Advancing winner ${winnerParticipant.name} to R:$nextRoundIndex M:$nextMatchIndex");
      if (nextRoundIndex < _rounds.length && nextMatchIndex < _rounds[nextRoundIndex].length) {
        Match nextMatch = _rounds[nextRoundIndex][nextMatchIndex]; _lastAdvancedToMatchId = nextMatch.id;
         if (kDebugMode) print("[Provider] selectWinner - BEFORE Assign to R:$nextRoundIndex M:$nextMatchIndex: P1=${nextMatch.participant1?.name ?? 'NULL'}, P2=${nextMatch.participant2?.name ?? 'NULL'}");
        if (currentMatchIndexInRound % 2 == 0) { _wasLastAdvanceToP1 = true; nextMatch.participant1 = winnerParticipant; if (kDebugMode) print("[Provider] selectWinner - Assigned P1 in R:$nextRoundIndex M:$nextMatchIndex"); }
        else { _wasLastAdvanceToP1 = false; nextMatch.participant2 = winnerParticipant; if (kDebugMode) print("[Provider] selectWinner - Assigned P2 in R:$nextRoundIndex M:$nextMatchIndex"); }
         if (kDebugMode) print("[Provider] selectWinner - AFTER Assign to R:$nextRoundIndex M:$nextMatchIndex: P1=${nextMatch.participant1?.name ?? 'NULL'}, P2=${nextMatch.participant2?.name ?? 'NULL'}");
         if (kDebugMode && nextRoundIndex == _rounds.length - 1) { print("!! Estado del Partido Final (R:$nextRoundIndex M:$nextMatchIndex) después de avance: P1=${nextMatch.participant1?.name ?? 'NULL'}, P2=${nextMatch.participant2?.name ?? 'NULL'}"); }
      } else { if (kDebugMode) print("[Provider] selectWinner - CRITICAL ERROR: Cannot find next match R:$nextRoundIndex M:$nextMatchIndex to advance winner."); }
    } else if (isFinalRound && winnerParticipant != null) {
      _winner = winnerParticipant; _isTournamentActive = false; _lastAdvancedToMatchId = null;
      if (kDebugMode) print("[Provider] selectWinner - FINAL ROUND! Tournament Winner set: ${_winner?.name}");
    } else { if (kDebugMode) print("[Provider] selectWinner - No advancement/finish condition met (isFinal:$isFinalRound, winnerNull:${winnerParticipant == null})"); }
    _canUndo = true; if (kDebugMode) print("[Provider] selectWinner - END. Notifying listeners."); notifyListeners();
  }

 void undoLastSelection() {
    if (!_canUndo || _lastAffectedMatchId == null || _lastWinner == null) { if (kDebugMode) print("Nada que deshacer o estado de deshacer inválido."); return; }
    if (kDebugMode) print("Deshaciendo última selección..."); Match? affectedMatch; Match? advancedToMatch;
    for (var round in _rounds) { for (var match in round) { if (match.id == _lastAffectedMatchId) affectedMatch = match; if (_lastAdvancedToMatchId != null && match.id == _lastAdvancedToMatchId) advancedToMatch = match; } }
    if (affectedMatch == null) { if (kDebugMode) print("Error Deshacer: No se encontró el partido afectado ID: $_lastAffectedMatchId"); _clearUndoState(); _canUndo = false; notifyListeners(); return; }
    if (kDebugMode) print("Revirtiendo ganador en Match ID: ${affectedMatch.id}. P1=${affectedMatch.participant1?.name}, P2=${affectedMatch.participant2?.name}"); affectedMatch.winnerId = null;
    if (advancedToMatch != null) { if (_wasLastAdvanceToP1) { if (kDebugMode) print("Revirtiendo P1=${advancedToMatch.participant1?.name} en Match ID: ${advancedToMatch.id}"); advancedToMatch.participant1 = null; } else { if (kDebugMode) print("Revirtiendo P2=${advancedToMatch.participant2?.name} en Match ID: ${advancedToMatch.id}"); advancedToMatch.participant2 = null; } }
    if (_winner != null && _winner?.id == _lastWinner?.id) { if (kDebugMode) print("Revirtiendo campeón del torneo: ${_winner?.name}. Reactivando torneo."); _winner = null; _isTournamentActive = true; }
    _clearUndoState(); _canUndo = false; notifyListeners(); if (kDebugMode) print("Deshacer completado.");
 }

 void _clearUndoState() {
    _lastAffectedMatchId = null;
    _lastAdvancedToMatchId = null;
    _lastWinner = null;
    // _originalOpponent = null; // Eliminado
    _wasLastAdvanceToP1 = false;
 }

  void resetTournament() {
    _participants = [];
    _rounds = [];
    _winner = null;
    _isTournamentActive = false;
    _tournamentError = null;
    _canUndo = false;
    _clearUndoState();
    if (kDebugMode) print("Torneo reseteado.");
    notifyListeners();
  }

 void _printDebugBracket() {
     if (_rounds.isEmpty) { print("DEBUG BRACKET: No hay rondas generadas."); return; }
     print("==== INICIO DEBUG BRACKET GENERADO ====");
     print("Número total de rondas generadas: ${_rounds.length}");
     for (int r = 0; r < _rounds.length; r++) {
        print("--- Ronda $r (${_rounds[r].length} matches/slots) ---");
        for (int m = 0; m < _rounds[r].length; m++) {
           final match = _rounds[r][m];
           String p1Name = match.participant1?.name ?? "NULL";
           String p2Name = match.participant2?.name ?? "NULL";
           String winnerName = match.winner?.name ?? "NULL";
           print("  R$r M$m: P1=$p1Name, P2=$p2Name, Winner=$winnerName");
        }
     }
     print("==== FIN DEBUG BRACKET GENERADO ====");
  }
}
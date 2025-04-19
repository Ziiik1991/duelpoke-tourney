import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/participant.dart';
import '../models/match.dart';
import 'package:uuid/uuid.dart';
// Quitar imports no usados si no implementas save/load
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

class TournamentProvider with ChangeNotifier {
  final _uuid = const Uuid();
  List<Participant> _participants = [];
  List<List<Match>> _rounds = [];
  Participant? _winner;
  bool _isTournamentActive = false;
  String? _tournamentError;

  // Estado para Deshacer (sin _originalOpponent)
  String? _lastAffectedMatchId;
  String? _lastAdvancedToMatchId;
  Participant? _lastWinner;
  // Participant? _originalOpponent; // <-- CAMPO ELIMINADO
  bool _wasLastAdvanceToP1 = false;
  bool _canUndo = false;

  List<Participant> get participants => List.unmodifiable(_participants);
  List<List<Match>> get rounds => List.unmodifiable(_rounds);
  Participant? get winner => _winner;
  bool get isTournamentActive => _isTournamentActive;
  bool get isTournamentFinished => _winner != null;
  String? get tournamentError => _tournamentError;
  int get participantCount => _participants.length;
  bool get canUndo => _canUndo;

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
    if (_participants.length >= 100) { // Límite 100
      _setError("Máximo 100 participantes alcanzado.");
      return;
    }
    final newParticipant = Participant(id: _uuid.v4(), name: name);
    _participants.add(newParticipant);
    notifyListeners();
  }

  void removeParticipant(String id) {
    _tournamentError = null;
    _participants.removeWhere((p) => p.id == id);
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

  bool canStartTournament() {
    final count = _participants.length;
    return count >= 3 && count <= 100; // Límite 100
  }

  void startTournament() {
    if (!canStartTournament()) {
      _setError("Se necesitan entre 3 y 100 participantes para iniciar.");
      notifyListeners();
      return;
    }
    _tournamentError = null;
    _winner = null;
    _rounds = _generateBracket(_participants);
    _isTournamentActive = true;
    _canUndo = false;
    _clearUndoState();
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
      List<Participant> shuffledParticipants = List.from(initialParticipants)..shuffle(Random());
      List<Participant> byeParticipants = shuffledParticipants.sublist(0, nB);
      List<Participant> playingParticipants = shuffledParticipants.sublist(nB);
      List<List<Match>> generatedRounds = List.generate(nR, (r) {
          int matchesInRound = nP2 ~/ pow(2, r + 1);
          return List.generate(matchesInRound, (m) => Match( id: _uuid.v4(), roundIndex: r, matchIndexInRound: m, ));
      });
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
                  if (nR > 1) {
                      int nextRoundIndex = 1;
                      int nextMatchIndex = (m / 2).floor();
                      if (nextRoundIndex < generatedRounds.length && nextMatchIndex < generatedRounds[nextRoundIndex].length) {
                          Match nextMatch = generatedRounds[nextRoundIndex][nextMatchIndex];
                          if (m % 2 == 0) { nextMatch.participant1 = byeWinner; } else { nextMatch.participant2 = byeWinner; }
                      }
                  }
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
              } else {
                 if(p1ListIndex < playingParticipants.length){
                    Participant p1 = playingParticipants[p1ListIndex];
                     currentMatch.participant1 = p1;
                     currentMatch.participant2 = null;
                     currentMatch.winnerId = p1.id;
                     realMatchesAssigned++;
                     playerIndex++;
                 }
              }
          }
      }
      return generatedRounds;
  }

  void selectWinner(String matchId, String winnerParticipantId) {
    if (!_isTournamentActive || isTournamentFinished) return;

    Match? targetMatch;
    int currentRoundIndex = -1;
    int currentMatchIndexInRound = -1;

    for (int r = 0; r < _rounds.length; r++) {
      for (int m = 0; m < _rounds[r].length; m++) {
        if (_rounds[r][m].id == matchId) {
          targetMatch = _rounds[r][m];
          currentRoundIndex = r;
          currentMatchIndexInRound = m;
          break;
        }
      }
      if (targetMatch != null) break;
    }

    if (targetMatch == null) return;
    if (targetMatch.isFinished) return;
    if (!targetMatch.isReadyToPlay) return;

    _clearUndoState();
    _lastAffectedMatchId = targetMatch.id;
    _lastWinner = targetMatch.participant1?.id == winnerParticipantId ? targetMatch.participant1 : targetMatch.participant2;
    // _originalOpponent = ... ; // <-- LÍNEA ELIMINADA
    targetMatch.winnerId = winnerParticipantId;
    Participant? winnerParticipant = targetMatch.winner;

    bool isFinalRound = currentRoundIndex == _rounds.length - 1;
    if (!isFinalRound && winnerParticipant != null) {
      int nextRoundIndex = currentRoundIndex + 1;
      int nextMatchIndex = (currentMatchIndexInRound / 2).floor();
      if (nextRoundIndex < _rounds.length && nextMatchIndex < _rounds[nextRoundIndex].length) {
        Match nextMatch = _rounds[nextRoundIndex][nextMatchIndex];
        _lastAdvancedToMatchId = nextMatch.id;
        if (currentMatchIndexInRound % 2 == 0) {
           _wasLastAdvanceToP1 = true;
           nextMatch.participant1 = winnerParticipant;
        } else {
           _wasLastAdvanceToP1 = false;
           nextMatch.participant2 = winnerParticipant;
        }
      }
    } else if (isFinalRound && winnerParticipant != null) {
      _winner = winnerParticipant;
      _isTournamentActive = false;
      _lastAdvancedToMatchId = null;
    }

    _canUndo = true;
    notifyListeners();
  }

 void undoLastSelection() {
    if (!_canUndo || _lastAffectedMatchId == null || _lastWinner == null) return;

    Match? affectedMatch;
    Match? advancedToMatch;

    for (var round in _rounds) {
       for (var match in round) {
          if (match.id == _lastAffectedMatchId) affectedMatch = match;
          if (_lastAdvancedToMatchId != null && match.id == _lastAdvancedToMatchId) advancedToMatch = match;
       }
    }

    if (affectedMatch == null) {
       _clearUndoState();
       _canUndo = false;
       notifyListeners();
       return;
    }

    affectedMatch.winnerId = null;

    if (advancedToMatch != null) {
       if (_wasLastAdvanceToP1) {
          advancedToMatch.participant1 = null;
       } else {
          advancedToMatch.participant2 = null;
       }
    }

    if (_winner != null && _winner?.id == _lastWinner?.id) {
        _winner = null;
        _isTournamentActive = true;
    }

    _clearUndoState();
    _canUndo = false;
    notifyListeners();
 }

 void _clearUndoState() {
    _lastAffectedMatchId = null;
    _lastAdvancedToMatchId = null;
    _lastWinner = null;
    // _originalOpponent = null; // <-- LÍNEA ELIMINADA
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
    notifyListeners();
  }
}
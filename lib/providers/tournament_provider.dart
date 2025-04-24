import 'dart:math';
import 'package:flutter/foundation.dart'; // Necesario para kDebugMode
import '../models/participant.dart';
import '../models/match.dart';
import 'package:uuid/uuid.dart';

// Tipo para devolver los parámetros calculados del bracket
typedef BracketParams =
    ({
      int virtualSize,
      int numRounds,
      int matchesR0,
      int numByes,
      int numPlayingR0,
      int realMatchesR0,
    });

/// Gestiona el estado y la lógica de un torneo de eliminación simple.
class TournamentProvider with ChangeNotifier {
  final _uuid = const Uuid();
  List<Participant> _participants = [];
  List<List<Match>> _rounds = [];
  Participant? _winner;
  bool _isTournamentActive = false;
  String? _tournamentError;

  // Estado para Deshacer
  String? _lastAffectedMatchId;
  String? _lastAdvancedToMatchId;
  Participant? _lastWinner;
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

  // --- Métodos Públicos ---
  void addParticipant(String name) {
    /* ... (igual que antes, límite 32) ... */
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
    if (_participants.length >= 32) {
      _setError("Máximo 32 participantes alcanzado.");
      return;
    }
    final newParticipant = Participant(id: _uuid.v4(), name: name);
    _participants.add(newParticipant);
    if (kDebugMode) print("Participante Añadido: ${newParticipant.name}");
    notifyListeners();
  }

  void removeParticipant(String id) {
    /* ... (igual que antes) ... */
    _tournamentError = null;
    final participantIndex = _participants.indexWhere((p) => p.id == id);
    if (participantIndex != -1) {
      if (kDebugMode) {
        print(
          "Participante Eliminado: ${_participants[participantIndex].name} (ID: $id)",
        );
      }
      _participants.removeAt(participantIndex);
      notifyListeners();
    } else {
      if (kDebugMode) {
        print("Error: No se encontró participante para eliminar con ID: $id");
      }
    }
  }

  void _setError(String message) {
    /* ... (igual que antes) ... */
    _tournamentError = message;
    if (kDebugMode) print("Error Establecido: $message");
    notifyListeners();
  }

  void clearError() {
    /* ... (igual que antes) ... */
    if (_tournamentError != null) {
      _tournamentError = null;
      notifyListeners();
    }
  }

  bool canStartTournament() {
    /* ... (igual, límite 3-32) ... */
    final count = _participants.length;
    return count >= 3 && count <= 32;
  }

  /// Inicia el torneo, generando el bracket.
  void startTournament() {
    if (!canStartTournament()) {
      _setError("Se necesitan entre 3 y 32 participantes para iniciar.");
      notifyListeners();
      return;
    }
    _tournamentError = null;
    _winner = null;
    _rounds = _generateBracket(_participants); // Generar estructura
    _isTournamentActive = true;
    _canUndo = false;
    _clearUndoState();
    if (kDebugMode) {
      print("Torneo iniciado con ${_participants.length} participantes.");
      _printDebugBracket();
    }
    notifyListeners();
  }

  // --- Lógica Principal del Bracket (Ahora más corta) ---

  /// Genera la estructura completa del bracket. Llama a helpers.
  List<List<Match>> _generateBracket(List<Participant> initialParticipants) {
    // 1. Calcular parámetros necesarios
    final BracketParams params = _calculateBracketParameters(
      initialParticipants.length,
    );
    if (params.numRounds == 0) return []; // No se puede generar si nP < 2

    // 2. Preparar listas de participantes (mezclados, byes, jugando)
    final (participantesBye, participantesJugando) = _prepareParticipantLists(
      initialParticipants,
      params.numByes,
    );

    // 3. Crear estructura de rondas vacía
    List<List<Match>> rondasGeneradas = _createEmptyRounds(
      params.numRounds,
      params.virtualSize,
    );

    // 4. Poblar la Ronda 0 con BYEs y partidos, y avanzar BYEs
    _populateRound0(
      rondasGeneradas,
      participantesBye,
      participantesJugando,
      params,
    );

    if (kDebugMode) {
      print("Bracket final generado con ${params.numRounds} rondas.");
    }
    return rondasGeneradas;
  }

  /// Selecciona un ganador y avanza si corresponde. Llama a helpers.
  /// (Variables locales principales en español)
  void selectWinner(String matchId, String winnerParticipantId) {
    if (kDebugMode) {
      print(
        "[Provider] selectWinner ENTRY - MatchID: $matchId, WinnerID: $winnerParticipantId",
      );
    }
    if (!_isTournamentActive || isTournamentFinished) {
      /* ... (validación) ... */
      return;
    }

    // 1. Encontrar el partido y sus índices
    final foundMatchInfo = _findMatchAndIndices(matchId);
    if (foundMatchInfo == null) {
      if (kDebugMode) {
        print("[Provider] selectWinner EXIT - Partido $matchId no encontrado.");
      }
      return;
    }

    final Match partidoObjetivo = foundMatchInfo.match;
    final int indiceRondaActual = foundMatchInfo.roundIndex;
    final int indicePartidoEnRonda = foundMatchInfo.matchIndex;

    // 2. Validar si se puede jugar
    if (partidoObjetivo.isFinished) {
      if (kDebugMode) {
        print(
          "[Provider] selectWinner EXIT - Partido ${partidoObjetivo.id} ya finalizado.",
        );
      }
      return;
    }
    if (!partidoObjetivo.isReadyToPlay) {
      if (kDebugMode) {
        print(
          "[Provider] selectWinner EXIT - Partido ${partidoObjetivo.id} no listo (P1:${partidoObjetivo.participant1?.name}, P2:${partidoObjetivo.participant2?.name}).",
        );
      }
      return;
    }

    // 3. Preparar Undo y asignar ganador actual
    _clearUndoState();
    _lastAffectedMatchId = partidoObjetivo.id;
    _lastWinner =
        partidoObjetivo.participant1?.id == winnerParticipantId
            ? partidoObjetivo.participant1
            : partidoObjetivo.participant2;
    if (kDebugMode) {
      print(
        "[Provider] selectWinner - Found Match R:$indiceRondaActual M:$indicePartidoEnRonda. Assigning winner...",
      );
    }
    partidoObjetivo.winnerId = winnerParticipantId;
    Participant? participanteGanador = partidoObjetivo.winner;

    // 4. Avanzar o finalizar
    bool esRondaFinal = indiceRondaActual == _rounds.length - 1;
    if (kDebugMode) {
      print(
        "[Provider] selectWinner - Check conditions: isFinalRound: $esRondaFinal, winnerParticipant exists: ${participanteGanador != null}",
      );
    }

    if (!esRondaFinal && participanteGanador != null) {
      // Llama a helper para avanzar
      _advanceWinnerToNextRound(
        partidoObjetivo,
        participanteGanador,
        indiceRondaActual,
        indicePartidoEnRonda,
      );
    } else if (esRondaFinal && participanteGanador != null) {
      // Llama a helper para finalizar
      _setTournamentWinner(participanteGanador);
    } else {
      if (kDebugMode) {
        print("[Provider] selectWinner - No advancement/finish condition met.");
      }
    }

    // 5. Habilitar undo y notificar
    _canUndo = true;
    if (kDebugMode) {
      print("[Provider] selectWinner - END. Notifying listeners.");
    }
    notifyListeners();
  }

  // --- Métodos Privados Auxiliares ---

  /// Calcula los parámetros básicos del bracket (tamaño, rondas, byes, etc.)
  BracketParams _calculateBracketParameters(int numParticipantes) {
    if (numParticipantes < 2) {
      return (
        virtualSize: 0,
        numRounds: 0,
        matchesR0: 0,
        numByes: 0,
        numPlayingR0: 0,
        realMatchesR0: 0,
      );
    }
    final int nP2 = pow(2, (log(numParticipantes) / log(2)).ceil()).toInt();
    final int nR = (log(nP2) / log(2)).toInt();
    final int nMR0 = nP2 ~/ 2;
    final int nB = nP2 - numParticipantes;
    final int nFP = numParticipantes - nB;
    final int nMA0 = nFP ~/ 2;
    if (kDebugMode) {
      print(
        "  _calculateBracketParameters: nP=$numParticipantes -> nP2=$nP2, nR=$nR, nMR0=$nMR0, nB=$nB, nFP=$nFP, nMA0=$nMA0",
      );
    }
    return (
      virtualSize: nP2,
      numRounds: nR,
      matchesR0: nMR0,
      numByes: nB,
      numPlayingR0: nFP,
      realMatchesR0: nMA0,
    );
  }

  /// Mezcla participantes y los separa en listas de BYE y Jugando.
  (List<Participant>, List<Participant>) _prepareParticipantLists(
    List<Participant> initialParticipants,
    int numByes,
  ) {
    List<Participant> participantesMezclados = List.from(initialParticipants)
      ..shuffle(Random());
    List<Participant> participantesBye = participantesMezclados.sublist(
      0,
      numByes,
    );
    List<Participant> participantesJugando = participantesMezclados.sublist(
      numByes,
    );
    return (participantesBye, participantesJugando);
  }

  /// Crea la estructura de lista de listas para las rondas, con objetos Match vacíos.
  List<List<Match>> _createEmptyRounds(int numRounds, int virtualSize) {
    List<List<Match>> rondasGeneradas = List.generate(numRounds, (r) {
      int partidosEnRonda = virtualSize ~/ pow(2, r + 1);
      if (kDebugMode) {
        print(
          "  _createEmptyRounds: Ronda $r: Creando $partidosEnRonda slots.",
        );
      }
      return List.generate(
        partidosEnRonda,
        (m) => Match(id: _uuid.v4(), roundIndex: r, matchIndexInRound: m),
      );
    });
    if (kDebugMode) print("  _createEmptyRounds: Estructura vacía creada.");
    return rondasGeneradas;
  }

  /// Asigna BYEs y Partidos Reales a la Ronda 0, y avanza los BYEs a Ronda 1.
  void _populateRound0(
    List<List<Match>> rondasGeneradas,
    List<Participant> participantesBye,
    List<Participant> participantesJugando,
    BracketParams params,
  ) {
    int indiceBye = 0;
    int indiceJugador = 0;
    int byesAsignados = 0;
    int partidosRealesAsignados = 0;
    final int numRondas = params.numRounds; // Obtener de params

    for (int m = 0; m < params.matchesR0; m++) {
      Match partidoActual = rondasGeneradas[0][m];
      if (byesAsignados < params.numByes) {
        // Asignar BYE
        if (indiceBye < participantesBye.length) {
          Participant ganadorPorBye = participantesBye[indiceBye++];
          partidoActual.participant1 = ganadorPorBye;
          partidoActual.winnerId = ganadorPorBye.id;
          byesAsignados++;
          if (kDebugMode) {
            print(
              "  _populateRound0: Asignando BYE a ${ganadorPorBye.name} en R:0 M:$m",
            );
          }
          // Avanzar BYE (si hay más rondas)
          if (numRondas > 1) {
            _advanceByeWinner(rondasGeneradas, ganadorPorBye, m);
          }
        } else {
          if (kDebugMode) {
            print(
              "  _populateRound0: Error Lógico - Más BYEs esperados que disponibles en R:0 M:$m",
            );
          }
        }
      } else if (partidosRealesAsignados < params.realMatchesR0) {
        // Asignar Partido Real
        int idxP1 = indiceJugador;
        int idxP2 = indiceJugador + 1;
        if (idxP2 < participantesJugando.length) {
          Participant p1 = participantesJugando[idxP1];
          Participant p2 = participantesJugando[idxP2];
          partidoActual.participant1 = p1;
          partidoActual.participant2 = p2;
          partidosRealesAsignados++;
          indiceJugador += 2;
          if (kDebugMode) {
            print(
              "  _populateRound0: Asignando Partido ${p1.name} vs ${p2.name} en R:0 M:$m",
            );
          }
        } else {
          // Jugador impar restante (BYE forzado)
          if (kDebugMode) {
            print(
              "  _populateRound0: Error CRÍTICO - Número impar de jugadores restantes en R:0 M:$m",
            );
          }
          if (idxP1 < participantesJugando.length) {
            Participant p1 = participantesJugando[idxP1];
            partidoActual.participant1 = p1;
            partidoActual.winnerId = p1.id;
            partidosRealesAsignados++;
            indiceJugador++;
            if (kDebugMode) {
              print(
                "  _populateRound0: WARN - Jugador ${p1.name} asignado como BYE forzado.",
              );
            }
            // Avanzar este BYE forzado también
            if (numRondas > 1) _advanceByeWinner(rondasGeneradas, p1, m);
          }
        }
      } else {
        if (kDebugMode) {
          print("  _populateRound0: Info - Slot virtual R:0 M:$m sin uso.");
        }
      }
    }
    if (kDebugMode) {
      /* ... (imprimir resumen R0) ... */
      int finalByeCount = rondasGeneradas[0].where((m) => m.isBye).length;
      int finalMatchCount =
          rondasGeneradas[0]
              .where(
                (m) =>
                    m.participant1 != null &&
                    m.participant2 != null &&
                    !m.isFinished,
              )
              .length;
      print(
        "  _populateRound0: R0 populada: $finalByeCount BYEs, $finalMatchCount partidos reales.",
      );
      if (finalByeCount != params.numByes ||
          finalMatchCount != params.realMatchesR0) {
        print("  _populateRound0: WARN - Conteos finales != Esperados");
      }
    }
  }

  /// Helper para avanzar un ganador de BYE a la siguiente ronda.
  void _advanceByeWinner(
    List<List<Match>> rondasGeneradas,
    Participant byeWinner,
    int matchIndexR0,
  ) {
    int siguienteR = 1;
    int siguienteM = (matchIndexR0 / 2).floor();
    // Comprobar límites
    if (siguienteR < rondasGeneradas.length &&
        siguienteM < rondasGeneradas[siguienteR].length) {
      Match siguientePartido = rondasGeneradas[siguienteR][siguienteM];
      if (matchIndexR0 % 2 == 0) {
        // Índice par R0 va a P1 de R1
        siguientePartido.participant1 = byeWinner;
        if (kDebugMode) {
          print(
            "    _advanceByeWinner: Avanzando BYE ${byeWinner.name} a R:1 M:$siguienteM como P1",
          );
        }
      } else {
        // Índice impar R0 va a P2 de R1
        siguientePartido.participant2 = byeWinner;
        if (kDebugMode) {
          print(
            "    _advanceByeWinner: Avanzando BYE ${byeWinner.name} a R:1 M:$siguienteM como P2",
          );
        }
      }
    } else {
      if (kDebugMode) {
        print(
          "    _advanceByeWinner: WARN - No se encontró R:$siguienteR M:$siguienteM para avanzar BYE.",
        );
      }
    }
  }

  /// Encuentra un partido por su ID y devuelve su info.
  ({Match match, int roundIndex, int matchIndex})? _findMatchAndIndices(
    String matchId,
  ) {
    for (int r = 0; r < _rounds.length; r++) {
      for (int m = 0; m < _rounds[r].length; m++) {
        if (_rounds[r][m].id == matchId) {
          return (match: _rounds[r][m], roundIndex: r, matchIndex: m);
        }
      }
    }
    return null; // No encontrado
  }

  /// Avanza al ganador al siguiente partido correspondiente.
  void _advanceWinnerToNextRound(
    Match partidoActual,
    Participant participanteGanador,
    int indiceRondaActual,
    int indicePartidoEnRonda,
  ) {
    int siguienteIndiceRonda = indiceRondaActual + 1;
    int siguienteIndicePartido = (indicePartidoEnRonda / 2).floor();
    if (kDebugMode) {
      print(
        "  _advanceWinner: Calculado next R:$siguienteIndiceRonda M:$siguienteIndicePartido",
      );
    }

    // Verificar límites
    if (siguienteIndiceRonda < _rounds.length &&
        siguienteIndicePartido < _rounds[siguienteIndiceRonda].length) {
      Match siguientePartido =
          _rounds[siguienteIndiceRonda][siguienteIndicePartido];
      _lastAdvancedToMatchId = siguientePartido.id; // Guardar para Undo

      if (kDebugMode) {
        print(
          "  _advanceWinner: BEFORE Assign to R:$siguienteIndiceRonda M:$siguienteIndicePartido: P1=${siguientePartido.participant1?.name ?? 'NULL'}, P2=${siguientePartido.participant2?.name ?? 'NULL'}",
        );
      }

      // Asignar a P1 si el índice actual era par, si no a P2
      if (indicePartidoEnRonda % 2 == 0) {
        _wasLastAdvanceToP1 = true;
        siguientePartido.participant1 = participanteGanador;
        if (kDebugMode) {
          print(
            "  _advanceWinner: Assigned P1 in R:$siguienteIndiceRonda M:$siguienteIndicePartido",
          );
        }
      } else {
        _wasLastAdvanceToP1 = false;
        siguientePartido.participant2 = participanteGanador;
        if (kDebugMode) {
          print(
            "  _advanceWinner: Assigned P2 in R:$siguienteIndiceRonda M:$siguienteIndicePartido",
          );
        }
      }

      if (kDebugMode) {
        print(
          "  _advanceWinner: AFTER Assign to R:$siguienteIndiceRonda M:$siguienteIndicePartido: P1=${siguientePartido.participant1?.name ?? 'NULL'}, P2=${siguientePartido.participant2?.name ?? 'NULL'}",
        );
      }

      // Imprimir estado final si se acaba de llenar la final
      if (kDebugMode && siguienteIndiceRonda == _rounds.length - 1) {
        print(
          "!! Estado del Partido Final (R:$siguienteIndiceRonda M:$siguienteIndicePartido) después de avance: P1=${siguientePartido.participant1?.name ?? 'NULL'}, P2=${siguientePartido.participant2?.name ?? 'NULL'}",
        );
      }
    } else {
      if (kDebugMode) {
        print(
          "  _advanceWinner: CRITICAL ERROR - Cannot find next match R:$siguienteIndiceRonda M:$siguienteIndicePartido.",
        );
      }
    }
  }

  /// Establece el ganador final del torneo.
  void _setTournamentWinner(Participant participanteGanador) {
    _winner = participanteGanador;
    _isTournamentActive = false; // Torneo terminado
    _lastAdvancedToMatchId = null; // No avanza más
    if (kDebugMode) {
      print(
        "[Provider] _setTournamentWinner: FINAL ROUND! Tournament Winner set: ${_winner?.name}",
      );
    }
  }

  // undoLastSelection (sin cambios internos, se podría refactorizar si se quisiera)
  void undoLastSelection() {
    if (!_canUndo || _lastAffectedMatchId == null || _lastWinner == null) {
      if (kDebugMode) print("Nada que deshacer.");
      return;
    }
    if (kDebugMode) print("Deshaciendo última selección...");
    Match? affectedMatch;
    Match? advancedToMatch;
    for (var round in _rounds) {
      for (var match in round) {
        if (match.id == _lastAffectedMatchId) affectedMatch = match;
        if (_lastAdvancedToMatchId != null &&
            match.id == _lastAdvancedToMatchId) {
          advancedToMatch = match;
        }
      }
    }
    if (affectedMatch == null) {
      if (kDebugMode) {
        print(
          "Error Deshacer: No se encontró partido afectado ID: $_lastAffectedMatchId",
        );
      }
      _clearUndoState();
      _canUndo = false;
      notifyListeners();
      return;
    }
    if (kDebugMode) {
      print(
        "Revirtiendo ganador en Match ID: ${affectedMatch.id}. P1=${affectedMatch.participant1?.name}, P2=${affectedMatch.participant2?.name}",
      );
    }
    affectedMatch.winnerId = null;
    if (advancedToMatch != null) {
      if (_wasLastAdvanceToP1) {
        if (kDebugMode) {
          print(
            "Revirtiendo P1=${advancedToMatch.participant1?.name} en Match ID: ${advancedToMatch.id}",
          );
        }
        advancedToMatch.participant1 = null;
      } else {
        if (kDebugMode) {
          print(
            "Revirtiendo P2=${advancedToMatch.participant2?.name} en Match ID: ${advancedToMatch.id}",
          );
        }
        advancedToMatch.participant2 = null;
      }
    }
    if (_winner != null && _winner?.id == _lastWinner?.id) {
      if (kDebugMode) {
        print("Revirtiendo campeón del torneo: ${_winner?.name}.");
      }
      _winner = null;
      _isTournamentActive = true;
    }
    _clearUndoState();
    _canUndo = false;
    notifyListeners();
    if (kDebugMode) print("Deshacer completado.");
  }

  // _clearUndoState (sin cambios internos)
  void _clearUndoState() {
    _lastAffectedMatchId = null;
    _lastAdvancedToMatchId = null;
    _lastWinner = null;
    _wasLastAdvanceToP1 = false;
  }

  // resetTournament (sin cambios internos)
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

  // _printDebugBracket (sin cambios internos)
  void _printDebugBracket() {
    if (_rounds.isEmpty) {
      print("DEBUG BRACKET: No hay rondas generadas.");
      return;
    }
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
} // Fin Clase TournamentProvider

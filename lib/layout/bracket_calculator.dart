import 'dart:math';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:flutter/painting.dart'; // Para Offset
// Asegúrate que las rutas sean correctas
import '../models/match.dart';
import '../constants/layout_constants.dart';

// Define un tipo 'record' para devolver el resultado del cálculo de forma ordenada.
typedef BracketLayoutResult =
    ({
      Map<String, Offset> positions, // Nombre del campo: positions
      double totalWidth, // Nombre del campo: totalWidth
      double totalHeight, // Nombre del campo: totalHeight
    });

/// Clase de utilidad estática para calcular las posiciones del bracket.
class BracketCalculator {
  /// Calcula posiciones para layout Izq/Der->Centro (Y Simple basada en índice 'm').
  /// Devuelve un BracketLayoutResult.
  static BracketLayoutResult calculateMirroredLayoutPositions(
    List<List<Match>> rounds,
  ) {
    // Variables locales para el cálculo
    Map<String, Offset> posicionesPartidos = {};
    double anchoTotalBracket = 0;
    double altoTotalBracket = 0;
    double maxAlturaCalculada = 0;
    double maxAnchoCalculado = 0;

    // --- Verificaciones iniciales ---
    if (rounds.isEmpty) {
      return (positions: {}, totalWidth: 0, totalHeight: 0);
    } // Nombres correctos
    final int rondasTotales = rounds.length;
    if (rondasTotales == 0) {
      return (positions: {}, totalWidth: 0, totalHeight: 0);
    } // Nombres correctos

    if (kDebugMode)
      print(
        "[Calculator] Calculating MIRRORED layout (Simple Index Y - Attempt 7) for $rondasTotales rounds...",
      );

    // Usar constantes importadas
    final double espaciadoVertical = kVerticalSpacing;
    final double pasoHorizontal = kMatchWidth + kHorizontalSpacing;

    // Estimación inicial de ancho y centro X
    int pasosAlCentro = (rondasTotales / 2).ceil();
    anchoTotalBracket = (pasosAlCentro * pasoHorizontal * 2) + kMatchWidth;
    final double centroX = anchoTotalBracket / 2;

    // Estimar altura inicial basada en R0
    int maxPartidosPorLadoR0 =
        (rounds.isNotEmpty && rounds[0].isNotEmpty)
            ? (rounds[0].length / 2).ceil()
            : 0;
    altoTotalBracket =
        (maxPartidosPorLadoR0 > 0
            ? (maxPartidosPorLadoR0 - 1) * espaciadoVertical
            : 0) +
        kMatchHeight;
    altoTotalBracket += kMatchHeight * 3; // Padding

    // --- Calcular Posiciones ---
    // (Lógica interna de cálculo de posiciones - sin cambios respecto a la última versión)
    for (int r = 0; r < rondasTotales; r++) {
      int partidosEnEstaRonda = rounds[r].length;
      if (partidosEnEstaRonda == 0) continue;
      bool esRondaFinal = r == rondasTotales - 1;
      int partidosIzquierda = (partidosEnEstaRonda / 2).floor();
      double inicioY = kMatchHeight * 1.5;
      for (int m = 0; m < partidosEnEstaRonda; m++) {
        if (m >= rounds[r].length) continue;
        Match partido = rounds[r][m];
        double actualX;
        double actualY;
        bool esRamaIzquierda = m < partidosIzquierda;
        int indiceEnRama;
        if (esRondaFinal && partidosEnEstaRonda == 1) {
          actualY = (altoTotalBracket / 2) - (kMatchHeight / 2);
          indiceEnRama = 0;
        } else {
          indiceEnRama = esRamaIzquierda ? m : m - partidosIzquierda;
          actualY = inicioY + indiceEnRama * espaciadoVertical;
        }
        if (esRondaFinal) {
          actualX = centroX - (kMatchWidth / 2);
        } else {
          if (esRamaIzquierda) {
            actualX = r * pasoHorizontal;
          } else {
            actualX = anchoTotalBracket - kMatchWidth - (r * pasoHorizontal);
          }
        }
        actualX = max(0, actualX);
        posicionesPartidos[partido.id] = Offset(actualX, actualY);
        maxAlturaCalculada = max(maxAlturaCalculada, actualY + kMatchHeight);
        maxAnchoCalculado = max(maxAnchoCalculado, actualX + kMatchWidth);
      }
    }

    // --- Ajustes finales a las dimensiones totales ---
    anchoTotalBracket = max(
      anchoTotalBracket,
      maxAnchoCalculado + kHorizontalSpacing,
    );
    altoTotalBracket = max(
      altoTotalBracket,
      maxAlturaCalculada + kMatchHeight * 1.5,
    );

    if (kDebugMode) {
      print("[Calculator] Layout Calculation Done.");
      print("Final Total Width: $anchoTotalBracket");
      print("Final Total Height: $altoTotalBracket");
      print("Positions calculated for ${posicionesPartidos.length} matches.");
    }

    // --- Devolver el resultado usando los NOMBRES CORRECTOS del typedef ---
    return (
      positions: posicionesPartidos,
      totalWidth: anchoTotalBracket, // <-- Asegúrate que sea totalWidth
      totalHeight: altoTotalBracket, // <-- Asegúrate que sea totalHeight
    );
  } // Fin calculateMirroredLayoutPositions
} // Fin clase BracketCalculator

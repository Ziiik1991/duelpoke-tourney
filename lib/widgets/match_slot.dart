import 'package:flutter/material.dart';
import '../models/match.dart';
import '../constants/layout_constants.dart'; // Importar constantes
import 'match_widget.dart'; // Importar el widget de partido real

/// Un widget que representa un "slot" o espacio en el bracket.
/// Decide si mostrar un partido jugable (MatchWidget),
/// un BYE, un placeholder de error, o un slot vacío.
class MatchSlot extends StatelessWidget {
  final Match? match; // El partido a mostrar (puede ser null)

  const MatchSlot({
    super.key,
    required this.match,
    // No necesita recibir alto/ancho, usa las constantes globales
  });

  @override
  Widget build(BuildContext context) {
    // Usamos las constantes importadas para tamaño
    const double alturaSlot = kMatchHeight;
    const double anchoSlot = kMatchWidth;

    return Container(
      height: alturaSlot,
      width: anchoSlot, // El Container padre establece el tamaño
      // decoration: BoxDecoration(border: Border.all(color: Colors.cyan.withOpacity(0.5))), // Borde de debug (opcional)
      child: Builder(
        builder: (context) {
          // Usar if/else if/else para claridad
          if (match == null) {
            // --- Slot Vacío ---
            return Container(
              height: alturaSlot,
              width: anchoSlot,
              decoration: BoxDecoration(
                color: Colors.grey[800]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.grey[700]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Text("?", style: TextStyle(color: Colors.grey[600])),
              ),
            );
          } else if (match!.isBye) {
            // --- Slot de BYE ---
            if (match!.winner != null) {
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade700.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      match!.winner!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "(BYE)",
                      style: TextStyle(
                        color: Colors.cyanAccent.withOpacity(0.8),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Container(
                height: alturaSlot,
                width: anchoSlot,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red[900]?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Center(
                  child: Text(
                    "BYE ERR",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              );
            }
          } else {
            // --- Partido Normal ---
            // Llama a MatchWidget SIN pasar widgetWidth (ya no lo necesita)
            return MatchWidget(
              match: match!,
              // widgetWidth: anchoSlot <-- Ya no se pasa
            );
          }
        },
      ),
    );
  }
}

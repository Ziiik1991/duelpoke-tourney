import 'package:flutter/material.dart';
import '../models/match.dart';
import '../constants/layout_constants.dart';
import 'match_widget.dart';

class MatchSlot extends StatelessWidget {
  final Match? match;

  const MatchSlot({
    super.key,
    required this.match,
    // No necesita recibir alto/ancho, usa las constantes globales
  });

  @override
  Widget build(BuildContext context) {
    const double alturaSlot = kMatchHeight;
    const double anchoSlot = kMatchWidth;

    return Container(
      height: alturaSlot,
      width: anchoSlot,

      child: Builder(
        builder: (context) {
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
            return MatchWidget(match: match!);
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode; // Para kDebugMode
import '../models/participant.dart'; // Necesita el modelo

/// Widget para mostrar un participante individual en la lista de registro.
class ParticipantListItem extends StatelessWidget {
  final Participant participant;
  final VoidCallback onRemove; // Función a llamar cuando se presiona el botón de eliminar
  final bool isRemoving; // Indica si se está animando la eliminación

  const ParticipantListItem({
    super.key,
    required this.participant,
    required this.onRemove,
    this.isRemoving = false, // Por defecto no se está eliminando
  });

  @override
  Widget build(BuildContext context) {
    // Padding vertical para separar items
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        // Color de fondo semi-transparente, cambia si se está eliminando
        color: isRemoving
              ? Colors.red.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        // InkWell para efecto visual al tocar (ripple)
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
          highlightColor: Theme.of(context).primaryColor.withOpacity(0.1),
          onTap: () {
             // Acción al tocar el item (actualmente ninguna, podría ser editar)
             if (kDebugMode) print("Tapped on ${participant.name}");
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                // Avatar circular con la inicial del participante
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  child: Text(
                    participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 15),
                // Nombre del participante (se expande para ocupar espacio)
                Expanded(
                  child: Text(
                    participant.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis, // Evita desbordamiento con nombres largos
                  ),
                ),
                const SizedBox(width: 10),
                // Botón para eliminar al participante
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Eliminar ${participant.name}',
                  onPressed: onRemove, // Llama a la función pasada desde la pantalla
                  splashRadius: 20,
                  visualDensity: VisualDensity.compact, // Botón más compacto
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
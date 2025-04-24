import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode; 
import '../models/participant.dart'; 

/// Widget para mostrar un participante individual en la lista de registro.
class ParticipantListItem extends StatelessWidget {
  final Participant participant;
  final VoidCallback
  onRemove; 
  final bool
  isRemoving; 

  const ParticipantListItem({
    super.key,
    required this.participant,
    required this.onRemove,
    this.isRemoving = false,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener el tema actual para usar sus colores y fuentes
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determinar color de fondo basado en si se está eliminando
    final Color backgroundColor =
        isRemoving
            ? colorScheme.errorContainer.withOpacity(
              0.6,
            ) // Color de error al borrar
            : colorScheme.surfaceContainerHighest.withOpacity(
              0.9,
            ); 

    // Definir forma con borde redondeado
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Bordes redondeados
      side: BorderSide(
        color: colorScheme.outlineVariant.withOpacity(0.5),
        width: 1,
      ), // Borde sutil
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
      ), // Espacio vertical entre items
      child: Material(
        // Usar Material para elevación, forma y color de fondo
        color: backgroundColor,
        shape: shape,
        elevation: 1, // Sombra ligera
        child: ListTile(
          // Usar ListTile para estructura estándar
          // Leading: Avatar a la izquierda
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary, // Color primario del tema
            foregroundColor:
                colorScheme.onPrimary, // Color de texto sobre primario
            radius: 18, // Tamaño del avatar
            child: Text(
              participant.name.isNotEmpty
                  ? participant.name[0].toUpperCase()
                  : '?',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          // Title: Nombre del participante
          title: Text(
            participant.name,
            // Usar estilo 'titleMedium' del tema (generalmente un poco más grande/negrita que body)
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ), // Color sobre superficie
            overflow: TextOverflow.ellipsis, // Truncar si es largo
            maxLines: 1,
          ),
          // Trailing: Botón Eliminar a la derecha
          trailing: IconButton(
            icon: Icon(
              Icons.delete_forever_outlined,
              color: colorScheme.error,
            ), // Icono de papelera y color de error
            tooltip: 'Eliminar ${participant.name}',
            onPressed: onRemove, // Llama a la función pasada como parámetro
            splashRadius: 22, // Área de efecto al tocar
            visualDensity: VisualDensity.compact, // Más compacto
            padding: EdgeInsets.zero, // Sin padding extra
            constraints:
                const BoxConstraints(), // Quitar constraints por defecto
          ),
          onTap: () {
            // Tap en toda la fila
            if (kDebugMode) print("Tapped on ${participant.name}");
            // Podría abrir diálogo de edición en el futuro
          },
          // Aplicar forma redondeada al InkWell interno de ListTile
          shape: shape,
          // Ajustar padding interno del ListTile si es necesario
          contentPadding: const EdgeInsets.only(
            left: 16.0,
            right: 8.0,
            top: 4.0,
            bottom: 4.0,
          ), // Ajustar padding
          dense: true, // Hacer el ListTile un poco más compacto verticalmente
        ),
      ),
    );
  }
}

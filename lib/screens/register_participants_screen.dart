import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'tournament_screen.dart';

class RegisterParticipantsScreen extends StatefulWidget {
  const RegisterParticipantsScreen({super.key});

  @override
  State<RegisterParticipantsScreen> createState() => _RegisterParticipantsScreenState();
}

class _RegisterParticipantsScreenState extends State<RegisterParticipantsScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Para validación opcional del TextField
  final ScrollController _scrollController = ScrollController(); // Para scroll automático

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  void _addParticipant() {
    _playClickSound();
    // Limpiar error anterior antes de intentar añadir
    context.read<TournamentProvider>().clearError();

    if (_nameController.text.trim().isNotEmpty) {
       context.read<TournamentProvider>().addParticipant(_nameController.text);
       _nameController.clear(); // Limpiar el campo después de añadir
       FocusScope.of(context).unfocus(); // Ocultar teclado

       // Scroll al final de la lista después de añadir
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (_scrollController.hasClients) {
              _scrollController.animateTo(
                 _scrollController.position.maxScrollExtent + 50, // Un poco más para asegurar visibilidad
                 duration: const Duration(milliseconds: 300),
                 curve: Curves.easeOut,
              );
           }
        });

    } else {
        // Mostrar snackbar si el campo está vacío (alternativa a provider error)
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
                 content: Text("Por favor, ingresa un nombre."),
                 backgroundColor: Colors.orangeAccent,
                 duration: Duration(seconds: 2),
                )
             );
    }
  }

  void _removeParticipant(String id) {
     _playClickSound();
     context.read<TournamentProvider>().removeParticipant(id);
  }

  void _startTournament() {
     _playClickSound();
     // Limpiar error antes de intentar iniciar
     context.read<TournamentProvider>().clearError();
     context.read<TournamentProvider>().startTournament();

     // Verificar si hubo error al iniciar (ej. número incorrecto de jugadores)
      final provider = context.read<TournamentProvider>();
      if (provider.tournamentError == null && provider.isTournamentActive) {
         Navigator.pushReplacement( // Usar pushReplacement para no volver aquí con back
          context,
          MaterialPageRoute(builder: (context) => const TournamentScreen()),
        );
      }
     // El error se mostrará automáticamente por el Consumer más abajo si existe
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Participantes'),
        leading: IconButton( // Botón para volver atrás
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             _playClickSound();
             // Opcional: Preguntar si quiere descartar
             Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Campo de Entrada y Botón Añadir ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinear items al inicio
              children: [
                Expanded(
                  child: Form( // Opcional: para validación integrada
                     key: _formKey,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Participante',
                        hintText: 'Ingresa un nombre...',
                        border: OutlineInputBorder(),
                      ),
                       onFieldSubmitted: (_) => _addParticipant(), // Añadir al presionar Enter
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                   padding: const EdgeInsets.only(top: 8.0), // Alinear con el campo de texto
                  child: ElevatedButton(
                    onPressed: _addParticipant,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12) // Hacerlo más cuadrado
                        ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

             // --- Mostrar Error del Provider ---
            Consumer<TournamentProvider>(
              builder: (context, provider, child) {
                if (provider.tournamentError != null) {
                  // Limpiar el error después de un tiempo o cuando el usuario interactúa
                  Future.delayed(const Duration(seconds: 4), () {
                     // Verificar si el error aún existe antes de limpiarlo
                     if (provider.tournamentError != null && mounted) {
                        provider.clearError();
                     }
                  });
                  return Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(top:8, bottom: 8),
                    color: Colors.redAccent.withOpacity(0.8),
                    child: Text(
                      provider.tournamentError!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else {
                  return const SizedBox.shrink(); // No mostrar nada si no hay error
                }
              },
            ),


            const SizedBox(height: 16),
            Text(
               // Usar Consumer para actualizar el contador dinámicamente
               context.select((TournamentProvider p) => 'Participantes: ${p.participantCount} / 16'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const Divider(),

            // --- Lista de Participantes ---
            Expanded(
              // Usar Consumer para reconstruir SÓLO la lista cuando cambien los participantes
              child: Consumer<TournamentProvider>(
                builder: (context, provider, child) {
                   final participants = provider.participants;
                   if (participants.isEmpty) {
                       return const Center(child: Text("Aún no hay participantes.", style: TextStyle(color: Colors.grey)));
                   }
                  return ListView.builder(
                    controller: _scrollController, // Añadir controller
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return Card( // Usar Card para mejor apariencia
                         margin: const EdgeInsets.symmetric(vertical: 4),
                         color: Colors.grey[800],
                        child: ListTile(
                          leading: CircleAvatar( // Mostrar inicial o número
                             backgroundColor: Theme.of(context).colorScheme.secondary,
                             foregroundColor: Theme.of(context).colorScheme.onSecondary,
                             child: Text(
                                 participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                                 style: const TextStyle(fontWeight: FontWeight.bold),
                                 ),
                          ),
                          title: Text(participant.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'Eliminar participante',
                            onPressed: () => _removeParticipant(participant.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),

            // --- Botón Iniciar Torneo ---
            Padding(
               padding: const EdgeInsets.symmetric(vertical: 8.0),
               child: Consumer<TournamentProvider>( // Escuchar cambios para habilitar/deshabilitar
                 builder: (context, provider, child) {
                   return ElevatedButton.icon(
                     icon: const Icon(Icons.play_circle_fill_outlined),
                     label: const Text('Iniciar Torneo'),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 15),
                       backgroundColor: provider.canStartTournament()
                           ? Theme.of(context).colorScheme.secondary // Color de acento si se puede iniciar
                           : Colors.grey[600], // Gris si no
                      foregroundColor: provider.canStartTournament()
                           ? Theme.of(context).colorScheme.onSecondary // Color de texto sobre acento
                           : Colors.grey[400],
                     ),
                     // Deshabilitar el botón si no se cumple la condición
                     onPressed: provider.canStartTournament() ? _startTournament : null,
                   );
                 }
               ),
             ),
          ],
        ),
      ),
    );
  }
}
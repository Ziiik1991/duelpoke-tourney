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
    context.read<TournamentProvider>().clearError();

    if (_nameController.text.trim().isNotEmpty) {
       context.read<TournamentProvider>().addParticipant(_nameController.text);
       _nameController.clear();
       FocusScope.of(context).unfocus();

       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
             _scrollController.animateTo(
                _scrollController.position.maxScrollExtent + 50,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
             );
          }
       });

    } else {
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
     context.read<TournamentProvider>().clearError();
     context.read<TournamentProvider>().startTournament();

      final provider = context.read<TournamentProvider>();
      if (provider.tournamentError == null && provider.isTournamentActive) {
         Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TournamentScreen()),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Participantes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             _playClickSound();
             Navigator.of(context).pop();
          },
        ),
      ),
      // ---> CONTENEDOR CON FONDO <---
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            // --> CAMBIA ESTO POR TU IMAGEN DE FONDO DE REGISTRO <--
            image: const AssetImage('assets/images/register_background.png'), // Ejemplo! Usa tu imagen
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode( // Filtro para oscurecer un poco
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding( // El Padding original ahora es hijo
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Campo de Entrada y Botón Añadir ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Form(
                       key: _formKey,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Participante',
                          hintText: 'Ingresa un nombre...',
                          // Quitar borde por defecto si se usa fillColor
                          // border: OutlineInputBorder(),
                        ),
                         onFieldSubmitted: (_) => _addParticipant(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton(
                      onPressed: _addParticipant,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12)
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
                    Future.delayed(const Duration(seconds: 4), () {
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
                    return const SizedBox.shrink();
                  }
                },
              ),


              const SizedBox(height: 16),
              // --- Contador de Participantes ---
              Container( // Fondo semitransparente para el contador
                 padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                 decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                    context.select((TournamentProvider p) => 'Participantes: ${p.participantCount} / 16'),
                   style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                   textAlign: TextAlign.center,
                 ),
               ),
              const Divider(),

              // --- Lista de Participantes ---
              Expanded(
                child: Consumer<TournamentProvider>(
                  builder: (context, provider, child) {
                     final participants = provider.participants;
                     if (participants.isEmpty) {
                         return Center(
                           child: Container( // Fondo para mensaje vacío
                             padding: const EdgeInsets.all(8.0),
                             decoration: BoxDecoration(
                               color: Colors.black.withOpacity(0.4),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: const Text(
                               "Aún no hay participantes.",
                               style: TextStyle(color: Colors.grey)
                              ),
                           ),
                         );
                     }
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        return Card(
                           margin: const EdgeInsets.symmetric(vertical: 4),
                           color: Colors.grey[800]?.withOpacity(0.85), // Hacer tarjeta un poco transparente
                          child: ListTile(
                            leading: CircleAvatar(
                               backgroundColor: Theme.of(context).colorScheme.secondary,
                               foregroundColor: Theme.of(context).colorScheme.onSecondary,
                               child: Text(participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?'),
                            ),
                            title: Text(participant.name, style: const TextStyle(color: Colors.white)), // Asegurar texto blanco
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
                 child: Consumer<TournamentProvider>(
                   builder: (context, provider, child) {
                     return ElevatedButton.icon(
                       icon: const Icon(Icons.play_circle_fill_outlined),
                       label: const Text('Iniciar Torneo'),
                       style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 15),
                         backgroundColor: provider.canStartTournament()
                             ? Theme.of(context).colorScheme.secondary
                             : Colors.grey[600],
                        foregroundColor: provider.canStartTournament()
                             ? Theme.of(context).colorScheme.onSecondary
                             : Colors.grey[400],
                       ),
                       onPressed: provider.canStartTournament() ? _startTournament : null,
                     );
                   }
                 ),
               ),
            ],
          ),
        ),
      ),
      // ---> FIN DEL CONTENEDOR CON FONDO <---
    );
  }
}

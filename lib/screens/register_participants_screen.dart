import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/participant.dart';
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'tournament_screen.dart';
import '../widgets/participant_list_item.dart'; // Importar widget movido
import 'package:flutter/foundation.dart'; // Para kDebugMode

/// Pantalla para registrar participantes.
class RegisterParticipantsScreen extends StatefulWidget {
  const RegisterParticipantsScreen({super.key});
  @override
  State<RegisterParticipantsScreen> createState() =>
      _RegisterParticipantsScreenState();
}

class _RegisterParticipantsScreenState
    extends State<RegisterParticipantsScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  List<Participant> _participantsList = [];

  @override
  void initState() {
    super.initState();
    _participantsList = List.from(
      context.read<TournamentProvider>().participants,
    );
    if (kDebugMode) {
      print(
        "RegisterScreen initState: Copied ${_participantsList.length} participants to local list.",
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  /// Añade participante (LÍMITE 32)
  void _addParticipant() {
    final provider = context.read<TournamentProvider>();
    if (provider.participantCount >= 32) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Máximo de 32 participantes alcanzado."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    _playClickSound();
    provider.clearError();
    final String nombre = _nameController.text.trim();
    if (nombre.isNotEmpty) {
      final int conteoPrevio = provider.participantCount;
      provider.addParticipant(nombre);
      if (provider.tournamentError == null &&
          provider.participantCount > conteoPrevio) {
        _nameController.clear();
        FocusScope.of(context).unfocus();
        final Participant nuevoParticipante = provider.participants.last;
        final int indiceInsercion = _participantsList.length;
        _participantsList.add(nuevoParticipante);
        _listKey.currentState?.insertItem(
          indiceInsercion,
          duration: const Duration(milliseconds: 300),
        );
        if (kDebugMode)
          print(
            "Added participant '${nuevoParticipante.name}' locally and inserting at index $indiceInsercion",
          );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        if (kDebugMode && provider.tournamentError != null)
          print("Add participant failed. Error: ${provider.tournamentError}");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa un nombre válido."),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Elimina participante
  void _removeParticipant(Participant participantToRemove, int index) {
    _playClickSound();
    final provider = context.read<TournamentProvider>();
    if (index < 0 ||
        index >= _participantsList.length ||
        _participantsList[index].id != participantToRemove.id) {
      if (kDebugMode)
        print(
          "Error: Invalid index $index or participant mismatch for removal.",
        );
      int indiceCorrecto = _participantsList.indexWhere(
        (p) => p.id == participantToRemove.id,
      );
      if (indiceCorrecto == -1) return;
      index = indiceCorrecto;
    }
    final Participant elemento = _participantsList[index];
    if (kDebugMode)
      print(
        "Attempting to remove participant ${elemento.name} at index $index",
      );
    provider.removeParticipant(participantToRemove.id);
    _participantsList.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedItem(elemento, animation),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildRemovedItem(Participant p, Animation<double> a) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
        child: ParticipantListItem(
          participant: p,
          onRemove: () {},
          isRemoving: true,
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    if (index < 0 || index >= _participantsList.length) {
      if (kDebugMode)
        print(
          "Error: buildAnimatedItem invalid index $index, list length is ${_participantsList.length}",
        );
      return const SizedBox.shrink();
    }
    final p = _participantsList[index];
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn)),
        child: ParticipantListItem(
          participant: p,
          onRemove: () => _removeParticipant(p, index),
        ),
      ),
    );
  }

  void _startTournament() {
    _playClickSound();
    final provider = context.read<TournamentProvider>();
    provider.clearError();
    provider.startTournament();
    if (provider.tournamentError == null && provider.isTournamentActive) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TournamentScreen()),
      );
    } else {
      if (kDebugMode && provider.tournamentError != null)
        print("Failed to start tournament. Error: ${provider.tournamentError}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final participantCount = provider.participantCount;
    final bool canStart = provider.canStartTournament();
    final bool canAddMore = participantCount < 32;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomButtonWidth = screenWidth * 0.6;
    const double inputFontSize = 18.0;

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
      body: Container(
        // --- AJUSTE DE FONDO AQUÍ ---
        decoration: BoxDecoration(
          image: DecorationImage(
            // NOTA: Sigue usando 'register_background.png'. Cambia a 'tournament_bg.png' si quieres la MISMA imagen.
            image: const AssetImage('assets/images/register_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              // Cambiar opacidad de 0.65 a 0.5 para aclarar
              Colors.black.withOpacity(0.5), // <-- Opacidad reducida
              BlendMode.darken,
            ),
          ),
        ),
        // --- FIN AJUSTE FONDO ---
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            children: [
              // --- Row Input y Conteo ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nombre Participante',
                                hintText: 'Ingresa...',
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                labelStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                hintStyle: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: inputFontSize,
                              ),
                              onFieldSubmitted:
                                  (_) => canAddMore ? _addParticipant() : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: canAddMore ? _addParticipant : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            shape: const CircleBorder(),
                            backgroundColor:
                                canAddMore
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.grey[700],
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20,
                            color:
                                canAddMore
                                    ? Theme.of(context).colorScheme.onSecondary
                                    : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Listos: $participantCount / 32',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Min: 3',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    participantCount < 3
                                        ? Colors.orangeAccent
                                        : Colors.grey[400],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: participantCount / 32.0,
                            backgroundColor: Colors.grey[700],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              participantCount < 3
                                  ? Colors.redAccent
                                  : (participantCount < 32
                                      ? Colors.indigoAccent
                                      : Colors.greenAccent),
                            ),
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Mensaje de Error
              Consumer<TournamentProvider>(
                builder: (context, provider, child) {
                  if (provider.tournamentError != null) {
                    Future.delayed(const Duration(seconds: 5), () {
                      if (provider.tournamentError != null && mounted) {
                        provider.clearError();
                      }
                    });
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.tournamentError!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              // Botón Iniciar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: SizedBox(
                    width: bottomButtonWidth,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_fill_outlined),
                      label: const Text('Iniciar Torneo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor:
                            canStart
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.grey[700],
                        foregroundColor:
                            canStart
                                ? Theme.of(context).colorScheme.onSecondary
                                : Colors.grey[400],
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: canStart ? _startTournament : null,
                    ),
                  ),
                ),
              ),
              const Divider(height: 15, thickness: 1),
              // Lista Animada
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedList(
                    key: _listKey,
                    controller: _scrollController,
                    initialItemCount: _participantsList.length,
                    itemBuilder: (context, index, animation) {
                      return _buildAnimatedItem(context, index, animation);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

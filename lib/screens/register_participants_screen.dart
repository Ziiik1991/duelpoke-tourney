import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/participant.dart';
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'tournament_screen.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

class RegisterParticipantsScreen extends StatefulWidget {
  const RegisterParticipantsScreen({super.key});
  @override
  State<RegisterParticipantsScreen> createState() => _RegisterParticipantsScreenState();
}

class _RegisterParticipantsScreenState extends State<RegisterParticipantsScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  List<Participant> _participantsList = [];

  @override
  void initState() {
     super.initState();
     _participantsList = List.from(context.read<TournamentProvider>().participants);
     if (kDebugMode) { print("RegisterScreen initState: Copied ${_participantsList.length} participants to local list."); }
  }

  @override
  void dispose() {
     _nameController.dispose();
     _scrollController.dispose();
     super.dispose();
  }

  void _playClickSound() { AudioManager.instance.playClickSound(); }

  void _addParticipant() {
     final provider = context.read<TournamentProvider>();
     // --- LÍMITE 32 ---
     if (provider.participantCount >= 32) {
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text("Máximo de 32 participantes alcanzado."), backgroundColor: Colors.orangeAccent, ) );
        return;
     }
     _playClickSound(); provider.clearError(); final name = _nameController.text.trim();
     if (name.isNotEmpty) { final previousCount = provider.participantCount; provider.addParticipant(name); if (provider.tournamentError == null && provider.participantCount > previousCount) { _nameController.clear(); FocusScope.of(context).unfocus(); final newParticipant = provider.participants.last; final insertIndex = _participantsList.length; _participantsList.add(newParticipant); _listKey.currentState?.insertItem(insertIndex, duration: const Duration(milliseconds: 300)); if (kDebugMode) print("Added participant '${newParticipant.name}' locally and inserting at index $insertIndex"); WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollController.hasClients) { _scrollController.animateTo( _scrollController.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, ); } }); } else { if (kDebugMode && provider.tournamentError != null) print("Add participant failed. Error: ${provider.tournamentError}"); } } else { ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text("Ingresa un nombre válido."), backgroundColor: Colors.orangeAccent, duration: Duration(seconds: 2), ) ); }
  }

  void _removeParticipant(Participant participantToRemove, int index) {
     _playClickSound(); final provider = context.read<TournamentProvider>();
     if (index < 0 || index >= _participantsList.length || _participantsList[index].id != participantToRemove.id) { if(kDebugMode) print("Error: Invalid index $index or participant mismatch for removal."); int correctIndex = _participantsList.indexWhere((p) => p.id == participantToRemove.id); if (correctIndex == -1) return; index = correctIndex; }
     final Participant item = _participantsList[index]; if (kDebugMode) print("Attempting to remove participant ${item.name} at index $index");
     provider.removeParticipant(participantToRemove.id);
     _participantsList.removeAt(index);
     _listKey.currentState?.removeItem( index, (context, animation) => _buildRemovedItem(item, animation), duration: const Duration(milliseconds: 300), );
  }

  Widget _buildRemovedItem(Participant p, Animation<double> a) {
     return FadeTransition( opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: SlideTransition( position: Tween<Offset>( begin: const Offset(1, 0), end: Offset.zero, ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)), child: ParticipantListItem( participant: p, onRemove: () {}, isRemoving: true, ), ), );
  }

  Widget _buildAnimatedItem(BuildContext context, int index, Animation<double> animation) {
     if (index < 0 || index >= _participantsList.length) { if(kDebugMode) print("Error: buildAnimatedItem called with invalid index $index, list length is ${_participantsList.length}"); return const SizedBox.shrink(); }
     final p = _participantsList[index];
     return FadeTransition( opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn), child: SlideTransition( position: Tween<Offset>( begin: const Offset(0, 0.5), end: Offset.zero, ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn)), child: ParticipantListItem( participant: p, onRemove: () => _removeParticipant(p, index), ), ), );
  }

  void _startTournament() {
     _playClickSound(); final provider = context.read<TournamentProvider>(); provider.clearError(); provider.startTournament(); if (provider.tournamentError == null && provider.isTournamentActive) { Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => const TournamentScreen()), ); } else { if (kDebugMode && provider.tournamentError != null) print("Failed to start tournament. Error: ${provider.tournamentError}"); }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final participantCount = provider.participantCount;
    final bool canStart = provider.canStartTournament();
    // --- LÍMITE 32 ---
    final bool canAddMore = participantCount < 32;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomButtonWidth = screenWidth * 0.6;
    const double inputFontSize = 18.0;

    return Scaffold(
      appBar: AppBar( title: const Text('Registrar Participantes'), leading: IconButton( icon: const Icon(Icons.arrow_back), onPressed: () { _playClickSound(); Navigator.of(context).pop(); }, ), ),
      body: Container(
        decoration: BoxDecoration( image: DecorationImage( image: const AssetImage('assets/images/register_background.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode( Colors.black.withOpacity(0.65), BlendMode.darken, ), ),),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            children: [
              Row( // Row Input/Conteo
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded( // Input + Add
                    flex: 3,
                    child: Row( crossAxisAlignment: CrossAxisAlignment.center, children: [ Expanded( child: Form( key: _formKey, child: TextFormField( controller: _nameController, decoration: InputDecoration( labelText: 'Nombre Participante', hintText: 'Ingresa...', filled: true, fillColor: Colors.white.withOpacity(0.1), border: OutlineInputBorder( borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none, ), labelStyle: TextStyle(color: Colors.white70, fontSize: 14), hintStyle: TextStyle(color: Colors.white54, fontSize: 14), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14) ), style: TextStyle( color: Colors.white, fontSize: inputFontSize ), onFieldSubmitted: (_) => canAddMore ? _addParticipant() : null, ), ), ), const SizedBox(width: 8), ElevatedButton( onPressed: canAddMore ? _addParticipant : null, style: ElevatedButton.styleFrom( padding: const EdgeInsets.all(12), shape: const CircleBorder(), backgroundColor: canAddMore ? Theme.of(context).colorScheme.secondary : Colors.grey[700], ), child: Icon( Icons.add, size: 20, color: canAddMore ? Theme.of(context).colorScheme.onSecondary : Colors.grey[400], ), ), ], ),
                  ),
                  const SizedBox(width: 16), // Espacio
                  Expanded( // Conteo
                     flex: 2,
                     child: Container( padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), decoration: BoxDecoration( color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8), ), child: Column( mainAxisSize: MainAxisSize.min, children: [ FittedBox( fit: BoxFit.scaleDown, child: Text( /* --- TEXTO LÍMITE 32 --- */ 'Listos: $participantCount / 32', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold), ), ), const SizedBox(height: 4), FittedBox( fit: BoxFit.scaleDown, child: Text( 'Min: 3', style: TextStyle(fontSize: 11, color: participantCount < 3 ? Colors.orangeAccent : Colors.grey[400]), ) ), const SizedBox(height: 5), LinearProgressIndicator( /* --- PROGRESS LÍMITE 32 --- */ value: participantCount / 32.0, backgroundColor: Colors.grey[700], valueColor: AlwaysStoppedAnimation<Color>( participantCount < 3 ? Colors.redAccent : (participantCount < 32 ? Colors.indigoAccent : Colors.greenAccent) ), minHeight: 5, borderRadius: BorderRadius.circular(3), ), ] ) ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer<TournamentProvider>( builder: (context, provider, child) { if (provider.tournamentError != null) { Future.delayed(const Duration(seconds: 5), () { if (provider.tournamentError != null && mounted) { provider.clearError(); } }); return Container( padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), margin: const EdgeInsets.only(top: 8, bottom: 8), decoration: BoxDecoration( color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(8), ), child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Expanded( child: Text( provider.tournamentError!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), textAlign: TextAlign.center, softWrap: true, ), ), ], ), ); } else { return const SizedBox.shrink(); } }, ),
              Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Center( child: SizedBox( width: bottomButtonWidth, child: ElevatedButton.icon( icon: const Icon(Icons.play_circle_fill_outlined), label: const Text('Iniciar Torneo'), style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: canStart ? Theme.of(context).colorScheme.secondary : Colors.grey[700], foregroundColor: canStart ? Theme.of(context).colorScheme.onSecondary : Colors.grey[400], textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), ), onPressed: canStart ? _startTournament : null, ), ), ), ),
              const Divider(height: 15, thickness: 1),
              Expanded( child: Material( color: Colors.transparent, child: AnimatedList( key: _listKey, controller: _scrollController, initialItemCount: _participantsList.length, itemBuilder: (context, index, animation) { return _buildAnimatedItem(context, index, animation); }, ), ), ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParticipantListItem extends StatelessWidget {
  final Participant participant; final VoidCallback onRemove; final bool isRemoving;
  const ParticipantListItem({ super.key, required this.participant, required this.onRemove, this.isRemoving = false, });
  @override Widget build(BuildContext context) { return Padding( padding: const EdgeInsets.symmetric(vertical: 4.0), child: Material( color: isRemoving ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12), child: InkWell( borderRadius: BorderRadius.circular(12), splashColor: Theme.of(context).primaryColor.withOpacity(0.2), highlightColor: Theme.of(context).primaryColor.withOpacity(0.1), onTap: () { }, child: Padding( padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), child: Row( children: [ CircleAvatar( backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8), foregroundColor: Theme.of(context).colorScheme.onSecondary, child: Text( participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.bold), ), ), const SizedBox(width: 15), Expanded( child: Text( participant.name, style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis, ), ), const SizedBox(width: 10), IconButton( icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Eliminar ${participant.name}', onPressed: onRemove, splashRadius: 20, visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, ), ], ), ), ), ), ); }
}
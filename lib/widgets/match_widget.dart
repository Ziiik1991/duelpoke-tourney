import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';     
import '../models/participant.dart'; 
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'package:flutter/foundation.dart'; 


class MatchWidget extends StatelessWidget {
  final Match match; 
  final double nameFontSize;
  final double widgetWidth;

  const MatchWidget({
    super.key,
    required this.match, 
    this.nameFontSize = 12.0,
    this.widgetWidth = 150.0
  });

  
  void _selectWinner(BuildContext context, Participant? potentialWinner) {
      if (potentialWinner == null) return;
      final provider = context.read<TournamentProvider>();

      if (kDebugMode) {
        print("[MatchWidget] Intento de seleccionar ganador:");
        print("  > Partido ID: ${match.id} (R${match.roundIndex} M${match.matchIndexInRound})");
        print("  > Ganador Potencial: ${potentialWinner.name} (ID: ${potentialWinner.id})");
        
        print("  > Condiciones: Torneo Activo=${provider.isTournamentActive}, Partido Listo=${match.isReadyToPlay}, Partido Terminado=${match.isFinished}");
      }

      
      if (provider.isTournamentActive && /* match.isReadyToPlay && */ !match.isFinished) {
          if (kDebugMode) print("[MatchWidget] ¡Condiciones (SIN ReadyCheck) CUMPLIDAS para ${match.id}! Llamando a provider.selectWinner...");

          AudioManager.instance.playClickSound();
          provider.selectWinner(match.id, potentialWinner.id);
          final bool tournamentHasJustFinished = provider.isTournamentFinished;
          if (!tournamentHasJustFinished) {
            AudioManager.instance.playWinMatchSound();
          }
      } else {
           if (kDebugMode) print("[MatchWidget] Condiciones (SIN ReadyCheck) NO CUMPLIDAS para ${match.id}. Selección ignorada.");
           
           if(kDebugMode && !provider.isTournamentActive) print(" -> Razón: Torneo NO activo.");
           if(kDebugMode && match.isFinished) print(" -> Razón: Partido YA terminado.");
           
      }
  }
  

  @override
  Widget build(BuildContext context) {
    
    final p1=match.participant1;final p2=match.participant2;final w=match.winner;final bool p1W=w!=null&&w.id==p1?.id;final bool p2W=w!=null&&w.id==p2?.id;final bool canP=context.select((TournamentProvider p)=>p.isTournamentActive)&&match.isReadyToPlay&&!match.isFinished;final bS=TextStyle(fontSize:nameFontSize,color:Colors.white);final wS=bS.copyWith(fontWeight:FontWeight.bold,color:Theme.of(context).colorScheme.secondary);final lS=bS.copyWith(color:Colors.grey[600],decoration:TextDecoration.lineThrough);final tS=bS.copyWith(color:Colors.grey[500],fontStyle:FontStyle.italic);return Container(width:widgetWidth,padding:const EdgeInsets.symmetric(vertical:4.0,horizontal:6.0),margin:const EdgeInsets.symmetric(vertical:4.0),decoration:BoxDecoration(color:Colors.grey[850],borderRadius:BorderRadius.circular(6.0),border:Border.all(color:canP?Colors.indigo[300]!:Colors.grey[700]!,width:1.0,),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.3),blurRadius:2,offset:const Offset(1,1),)]),child:Column(mainAxisSize:MainAxisSize.min,children:[_buildParticipantRow(context:context,participant:p1,style:match.isFinished?(p1W?wS:lS):(p1==null?tS:bS),isWinner:p1W,onTap:canP?()=>_selectWinner(context,p1):null,),const Divider(height:4,thickness:1,color:Colors.grey),_buildParticipantRow(context:context,participant:p2,style:match.isFinished?(p2W?wS:lS):(p2==null?tS:bS),isWinner:p2W,onTap:canP?()=>_selectWinner(context,p2):null,),],),);
   }

  Widget _buildParticipantRow({ required BuildContext context, required Participant? participant, required TextStyle style, required bool isWinner, required VoidCallback? onTap, }) {
    
    return InkWell(onTap:onTap,splashColor:onTap!=null?Theme.of(context).colorScheme.secondary.withOpacity(0.3):Colors.transparent,highlightColor:onTap!=null?Theme.of(context).colorScheme.secondary.withOpacity(0.1):Colors.transparent,child:Container(padding:const EdgeInsets.symmetric(vertical:6.0),child:Row(children:[if(isWinner)Icon(Icons.star,color:Theme.of(context).colorScheme.secondary,size:nameFontSize+2),if(isWinner)const SizedBox(width:4),Expanded(child:Text(participant?.name??'Por determinar',style:style,overflow:TextOverflow.ellipsis,),),if(onTap!=null)Icon(Icons.touch_app_outlined,size:nameFontSize+2,color:Colors.grey[600]),],),),);
   }
} 
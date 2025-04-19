import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tournament_provider.dart';
import 'register_participants_screen.dart';
import '../services/audio_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioManager.instance.init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentProvider = Provider.of<TournamentProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.4;
    const double buttonFontSize = 20.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_welcome.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  errorBuilder: (c, e, s) => const Icon(Icons.shield_outlined,
                      size: 100, color: Colors.white70),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: const Text('Nuevo Torneo'),
                    style: ElevatedButton.styleFrom(
                      textStyle: GoogleFonts.lato(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      _playClickSound();
                      AudioManager.instance.stopBackgroundMusic();
                      tournamentProvider.resetTournament();
                      AudioManager.instance.playBackgroundMusic();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterParticipantsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: buttonWidth,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Salir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.lato(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      _playClickSound();
                      if (!kIsWeb) {
                        SystemNavigator.pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Cierra la pestaña del navegador para salir.")),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
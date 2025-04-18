import 'dart:typed_data'; // Para Uint8List del PDF en web
import 'dart:convert'; // Para base64Encode en web
import 'dart:io'; // Para File y Platform
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Para descarga en web (ignorar error si no compilas web)

import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar plataforma web
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // Para cargar assets al PDF
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart'; // Para rutas de guardado
import 'package:pdf/pdf.dart'; // Para PDF
import 'package:pdf/widgets.dart' as pw; // Widgets de PDF con prefijo
import 'package:open_filex/open_filex.dart'; // Para abrir PDF

import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'welcome_screen.dart';

class FinalScreen extends StatefulWidget {
  const FinalScreen({super.key});

  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.elasticOut);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: const Interval(0.3, 1.0, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
       if(mounted) {
         _animationController.forward();
       }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

   void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  void _startNewTournament() {
     _playClickSound();
     context.read<TournamentProvider>().resetTournament();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
  }

  Future<void> _generateAndSavePdf(String winnerName) async {
    final pdf = pw.Document();
    // Asegúrate de tener 'logo.png' en 'assets/images/'
    final ByteData logoBytes = await rootBundle.load('assets/images/logo.png');
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(height: 80, child: pw.Image(logoImage)),
                  pw.Column(
                     children: [
                        pw.Text('Certificado Oficial', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text('DuelPoke Tourney', style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic)),
                     ]
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Otorgado a:', style: const pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: pw.BoxDecoration( border: pw.Border.all(color: PdfColors.indigo, width: 2), borderRadius: pw.BorderRadius.circular(5)),
                        child: pw.Text( winnerName, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900), textAlign: pw.TextAlign.center),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text('Por alcanzar el título de', style: const pw.TextStyle(fontSize: 14), textAlign: pw.TextAlign.center),
                      pw.SizedBox(height: 10),
                      pw.Text( '¡Maestro Pokémon!', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800), textAlign: pw.TextAlign.center),
                    ]
                  ),
                  pw.Text( 'Emitido el: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600) ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // --- Lógica de Guardado/Descarga ---
    try {
      if (kIsWeb) {
        // --- Guardado para WEB (CORREGIDO) ---
        final Uint8List pdfBytes = await pdf.save();
        final base64Pdf = base64Encode(pdfBytes);
        // Se crea el elemento y se usan los métodos directamente con '..'
        // sin necesidad de asignar a la variable 'anchor'.
        html.AnchorElement(
            href: 'data:application/pdf;base64,$base64Pdf'
        )
          ..setAttribute("download", "certificado_maestro_${winnerName.replaceAll(' ', '_')}.pdf")
          ..click(); // Inicia la descarga

         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Iniciando descarga del PDF...'))
             );
         }
         // --- FIN CORRECCIÓN WEB ---

      } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        // --- Guardado para Móvil/Desktop ---
         final Directory directory = await getApplicationDocumentsDirectory();
         final String filePath = '${directory.path}/certificado_maestro_${winnerName.replaceAll(' ', '_')}.pdf';
         final File file = File(filePath);
         await file.writeAsBytes(await pdf.save());

         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: const Text('PDF guardado en Documentos'), action: SnackBarAction( label: 'Abrir', onPressed: () async { await OpenFilex.open(filePath); })));
          }
      } else {
           if (mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("Guardado de archivos no soportado.")) ); }
      }
    } catch (e) {
      print("Error al generar/guardar/abrir PDF: $e");
       if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text("Error al procesar PDF: $e")) ); }
    }
  }


  @override
  Widget build(BuildContext context) {
    final winner = context.watch<TournamentProvider>().winner;
    final String winnerName = winner?.name ?? 'Desconocido';
    final String masterTitle = 'Maestro Pokémon\n$winnerName';

    return Scaffold(
      body: Container(
         decoration: BoxDecoration(
           // Asegúrate que el fondo que quieres esté activo (imagen o gradiente)
           image: DecorationImage(
              image: const AssetImage('assets/images/victory_bg.png'), // <-- USA TU IMAGEN DE VICTORIA
              fit: BoxFit.cover,
              // colorFilter: ColorFilter.mode( ... ), // Opcional
           ),
           // gradient: LinearGradient( ... ), // O usa un gradiente
         ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(Icons.emoji_events, size: 150.0, color: Colors.amberAccent,
                     shadows: [ Shadow( color: Colors.black54, blurRadius: 10.0, offset: Offset(4, 4)) ],
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text('¡Felicidades!', style: GoogleFonts.pressStart2p(fontSize: 28, color: Colors.white,
                      shadows: [ const Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(2, 2)) ],
                    ), textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                 FadeTransition(
                   opacity: _fadeAnimation,
                   child: Text( masterTitle, style: GoogleFonts.pressStart2p( fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3,
                       shadows: [ const Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(3, 3)) ],
                     ), textAlign: TextAlign.center,
                   ),
                 ),
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Jugar Nuevo Torneo'),
                     style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, textStyle: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold) ),
                    onPressed: _startNewTournament,
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Guardar Certificado PDF'),
                    style: ElevatedButton.styleFrom( backgroundColor: Colors.teal[600], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    onPressed: () {
                       final currentWinner = context.read<TournamentProvider>().winner;
                       if (currentWinner != null) {
                         _generateAndSavePdf(currentWinner.name);
                       } else {
                          if(mounted) {
                             ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("Error: No se pudo determinar el ganador.")) );
                          }
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
} // Fin _FinalScreenState
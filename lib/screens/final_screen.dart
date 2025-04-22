import 'dart:typed_data'; // Para manejar bytes (PDF, imágenes)
import 'dart:convert'; // Para Base64
import 'dart:io';
import 'dart:html' as html; // Específico para web (descargar PDF)
import 'package:flutter/foundation.dart'; // Para kIsWeb, kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Para cargar assets (logo)
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart'; // Para obtener rutas de guardado
import 'package:pdf/pdf.dart'; // Clases base de la librería PDF
import 'package:pdf/widgets.dart' as pw; // Widgets para construir el PDF
import 'package:open_filex/open_filex.dart'; // Para abrir el PDF guardado
import '../providers/tournament_provider.dart';
import '../services/audio_manager.dart';
import 'welcome_screen.dart';

/// Pantalla que se muestra al finalizar el torneo, mostrando al ganador.
class FinalScreen extends StatefulWidget {
  const FinalScreen({super.key});
  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen>
    with SingleTickerProviderStateMixin {
  // Controladores para animaciones de entrada
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Configurar controlador de animación
    _animationController = AnimationController(
      vsync: this, // Necesario para TickerProvider
      duration: const Duration(milliseconds: 1200), // Duración de la animación
    );
    // Definir curvas de animación
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ); // Efecto rebote
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ); // Aparece después
    // Iniciar animación cuando el widget esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // Liberar controlador
    super.dispose();
  }

  /// Reproduce sonido de clic.
  void _playClickSound() {
    AudioManager.instance.playClickSound();
  }

  /// Reinicia el torneo y vuelve a la pantalla de bienvenida.
  void _startNewTournament() {
    _playClickSound();
    context.read<TournamentProvider>().resetTournament(); // Limpia el provider
    // Navega reemplazando todas las pantallas anteriores
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (r) => false, // Elimina todas las rutas anteriores
    );
  }

  /// Genera un PDF de certificado y lo guarda o descarga.
  Future<void> _generateAndSavePdf(String winnerName) async {
    final pdf = pw.Document(); // Crear documento PDF
    pw.MemoryImage? logoImage; // Variable para guardar la imagen del logo

    // Intentar cargar el logo desde los assets
    try {
      final ByteData logoBytes = await rootBundle.load(
        'assets/images/logo.png',
      );
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      if (kDebugMode) print("Logo cargado para PDF.");
    } catch (e) {
      if (kDebugMode) print("Error loading logo for PDF: $e");
      // Continuar sin logo si falla la carga
    }

    // --- Añadir página al PDF ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // Tamaño estándar
        build: (pw.Context context) {
          // Función que construye el contenido
          // Usar widgets de la librería 'pdf/widgets.dart' (prefijo 'pw')
          return pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceAround, // Espacio vertical
                crossAxisAlignment:
                    pw.CrossAxisAlignment.center, // Centrado horizontal
                children: [
                  // Mostrar logo si se cargó, si no un placeholder
                  if (logoImage != null)
                    pw.Container(height: 80, child: pw.Image(logoImage)),
                  if (logoImage == null)
                    pw.Container(
                      height: 80,
                      child: pw.Text('[Logo no disponible]'),
                    ),

                  // Título del certificado
                  pw.Column(
                    children: [
                      pw.Text(
                        'Certificado Oficial',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'DuelPoke Tourney',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),

                  // Sección del Ganador
                  pw.Column(
                    children: [
                      pw.Text(
                        'Otorgado a:',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(height: 10),
                      // Nombre del ganador resaltado
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.indigo,
                            width: 2,
                          ),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Text(
                          winnerName,
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Text(
                        'Por alcanzar el título de',
                        style: const pw.TextStyle(fontSize: 14),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      // Título obtenido
                      pw.Text(
                        '¡Maestro Pokémon!',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),

                  // Fecha de emisión
                  pw.Text(
                    'Emitido el: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ); // Fin addPage

    // --- Guardar o Descargar el PDF ---
    try {
      if (kIsWeb) {
        // Si estamos en la web
        final Uint8List pdfBytes = await pdf.save(); // Obtener bytes del PDF
        final base64Pdf = base64Encode(pdfBytes); // Codificar a Base64
        // Crear un link invisible para iniciar la descarga en el navegador
        final anchor =
            html.AnchorElement(href: 'data:application/pdf;base64,$base64Pdf')
              ..setAttribute(
                "download",
                "certificado_maestro_${winnerName.replaceAll(' ', '_')}.pdf",
              ) // Nombre del archivo
              ..click(); // Simular clic para descargar
        html.document.body?.children.remove(anchor); // Limpiar el link del HTML
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Descargando PDF...')));
      } else {
        // Si estamos en Móvil o Escritorio
        // Obtener directorio de guardado apropiado
        final Directory directory;
        if (Platform.isAndroid) {
          directory =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        } // Descargas o Documentos en Android
        else {
          directory = await getApplicationDocumentsDirectory();
        } // Documentos en iOS, macOS, Linux, Windows

        final String filePath =
            '${directory.path}/certificado_maestro_${winnerName.replaceAll(' ', '_')}.pdf';
        final File file = File(filePath);
        await file.writeAsBytes(
          await pdf.save(),
        ); // Escribir los bytes al archivo

        if (kDebugMode) print("PDF guardado en: $filePath");
        // Mostrar notificación con opción para abrir el archivo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF guardado en ${directory.path}'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Abrir',
                onPressed: () async {
                  try {
                    await OpenFilex.open(filePath);
                  } catch (e) {
                    if (kDebugMode) print("Error al abrir PDF: $e");
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Manejar errores al guardar/descargar
      if (kDebugMode) print("Error al generar/guardar PDF: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al generar o guardar PDF.")),
        );
    }
  } // Fin _generateAndSavePdf

  @override
  Widget build(BuildContext context) {
    // Obtener el ganador del provider
    final winner = context.watch<TournamentProvider>().winner;
    final String winnerName =
        winner?.name ??
        'Campeón Desconocido'; // Nombre por defecto si algo falla
    final String masterTitle =
        'Maestro Pokémon\n$winnerName'; // Texto principal

    return Scaffold(
      body: Container(
        // Fondo de victoria
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/victory_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            // Para pantallas pequeñas
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de trofeo animado
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(
                    Icons.emoji_events,
                    size: 150.0,
                    color: Colors.amberAccent,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10.0,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Texto "Felicidades" animado
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    '¡Felicidades!',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 28,
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          color: Colors.black45,
                          blurRadius: 5,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // Nombre del ganador animado
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    masterTitle,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                      shadows: [
                        const Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 60), // Espacio grande
                // Botón "Jugar Nuevo Torneo"
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Jugar Nuevo Torneo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      textStyle: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _startNewTournament,
                  ),
                ),
                const SizedBox(height: 20),
                // Botón "Guardar Certificado PDF"
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Guardar Certificado PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      final currentWinner =
                          context.read<TournamentProvider>().winner;
                      if (currentWinner != null) {
                        _generateAndSavePdf(currentWinner.name);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Error: No se pudo determinar el ganador.",
                              ),
                            ),
                          );
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
}

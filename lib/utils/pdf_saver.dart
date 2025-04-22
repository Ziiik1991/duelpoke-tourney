// Exporta el stub por defecto
export 'pdf_saver_stub.dart'
    // PERO si estamos compilando para web (donde dart.library.html existe),
    // exporta la implementación web en su lugar.
    if (dart.library.html) 'pdf_saver_web.dart';

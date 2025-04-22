// Altura de cada cajita de partido
const double kMatchHeight = 85.0;
// Ancho de cada cajita de partido
const double kMatchWidth = 150.0;
// espacio horizontal GRANDE entre columnas de rondas
const double kHorizontalSpacing = 180.0;
//  espacio vertical PEQUEÑO entre partidos de la misma ronda
const double kVerticalSpacingMultiplier = 0.05;

// espaciado vertical real
final double kVerticalSpacing =
    kMatchHeight + (kVerticalSpacingMultiplier * kMatchHeight);



// Altura de cada cajita de partido
const double kMatchHeight = 85.0;
// Ancho de cada cajita de partido
const double kMatchWidth = 150.0;
// Espacio horizontal GRANDE entre columnas de rondas
const double kHorizontalSpacing = 180.0;
// Factor para calcular el espacio vertical PEQUEÑO entre partidos de la misma ronda
const double kVerticalSpacingMultiplier = 0.05;

// Calculamos el espaciado vertical real una vez
final double kVerticalSpacing = kMatchHeight + (kVerticalSpacingMultiplier * kMatchHeight);
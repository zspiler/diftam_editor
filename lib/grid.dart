const gridSize = 25;

double snapToGrid(double value, int gridSize) {
  return (value / gridSize).round() * gridSize * 1.0;
}

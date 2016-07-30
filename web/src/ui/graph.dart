// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

/// Base [n] logarithm of [x]
num logN(num n, num x) => log(x) / log(n);

/// Particle count graph
class ParticleGraph extends CustomElement {
  static const defaultWidth = 330;
  static const defaultHeight = 250;
  static const gridMinSize = 30;
  static const gridLineSize = 2;
  static const lineDeltaDistance = 100;
  static const lineDeltaThreshold = 5;

  /// Rendering canvas
  final CanvasElement node;

  /// 2D rendering context
  CanvasRenderingContext2D ctx;

  /// Line colors
  List<Vector3> colors = new List();

  /// Entered particle count
  final List<List<int>> entered = new List();

  /// Sticked particle count
  final List<List<int>> sticked = new List();

  ParticleGraph() : node = new CanvasElement() {
    node.classes.add('particle-graph');
    node.width = defaultWidth;
    node.height = defaultHeight;
    ctx = node.getContext('2d');
    _scheduleFrame();
  }

  /// Add data point
  void addDataPoints(List<int> _entered, List<int> _sticked) {
    entered.add(_entered);
    sticked.add(_sticked);
  }

  /// Redraw
  void redraw() {
    if (!(node.clientWidth == 0 || entered.isEmpty)) {
      // Clear the canvas.
      ctx.clearRect(0, 0, defaultWidth, defaultHeight);

      // Get the largest data point.
      final maxValue = entered.reduce(
          (List<int> a, List<int> b) => [max(a.reduce(max), b.reduce(max))])[0];

      final dX = defaultWidth / entered.length; // Delta X
      final dY = defaultHeight / maxValue; // Delta Y
      final skip = (entered.length / defaultWidth).ceil();
      final gridx = pow(2,
              logN(2, gridMinSize / (defaultWidth / entered.length)).ceil()) *
          (defaultWidth / entered.length);

      // Draw grid.
      ctx.lineWidth = 1;
      ctx.setStrokeColorRgb(85, 85, 85);
      for (var x = 0; x < defaultWidth; x += gridx) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, defaultHeight);
        ctx.stroke();
      }

      // Set stroke line width for all plotted lines.
      ctx.lineWidth = gridLineSize;

      // Iterate through all particle types and draw their line.
      for (var type = 0; type < colors.length; type++) {
        // Set particle type color.
        ctx.setStrokeColorRgb((colors[type].x * 255).round(),
            (colors[type].y * 255).round(), (colors[type].z * 255).round());

        // Start graph path.
        ctx.beginPath();
        for (var i = 0; i < entered.length; i += skip) {
          final thisEntered = entered[i][type];

          // Compute plot x and y.
          final x = i * dX;
          var y = defaultHeight - thisEntered * dY;

          // Displace y if there are other lines on this coordinate.
          //
          // There is a nasty exception where two lines that go in a different
          // direction cross each other. This case should be discarded.
          if (entered.length > lineDeltaDistance && i > lineDeltaDistance) {
            for (var t = type + 1; t < colors.length; t++) {
              final delta =
                  (entered[i][t] - entered[i - lineDeltaDistance][t]) -
                      (thisEntered - entered[i - lineDeltaDistance][type]);
              if ((entered[i][t] - thisEntered).abs() * dY < gridLineSize &&
                  delta.abs() <= lineDeltaThreshold) {
                y += gridLineSize;
              }
            }
          }

          if (i == 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
        }
        ctx.stroke();
      }
    }

    _scheduleFrame();
  }

  /// Schedule a new render cycle.
  void _scheduleFrame() {
    window.requestAnimationFrame((num time) {
      redraw();
    });
  }
}

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
  static const lineDeltaDistance = 100; // TODO: try to eliminate this
  static const lineDeltaThreshold = 5;

  /// Rendering canvas
  final CanvasElement node;

  /// 2D rendering context
  CanvasRenderingContext2D ctx;

  /// Particle type labels (for CSV export)
  List<String> labels = new List<String>();

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

  /// Generate CSV data.
  String generateCsv() {
    final data = new List<List<dynamic>>();

    // Add table headers.
    data.add(['Step']
      ..addAll(new List<String>.generate(
          labels.length, (int i) => '${labels[i]} (entered)'))
      ..addAll(new List<String>.generate(
          labels.length, (int i) => '${labels[i]} (sticked)')));

    // Add all rows.
    for (var i = 0; i < entered.length; i++) {
      data.add([i]..addAll(entered[i])..addAll(sticked[i]));
    }

    // Generate CSV.
    return const ListToCsvConverter().convert(data);
  }

  /// Add data point
  void addDataPoints(List<int> _entered, List<int> _sticked) {
    entered.add(_entered);
    sticked.add(_sticked);
  }

  /// Redraw
  /// TODO: line smoothing
  /// TODO: grid line fade
  /// TODO: draw sticked line using black dashes.
  void redraw() {
    if (!(node.clientWidth == 0 || entered.isEmpty)) {
      // Clear the canvas.
      ctx.clearRect(0, 0, defaultWidth, defaultHeight);

      // Get the largest data point.
      final maxValue = max(
          entered.fold(
              0, (int prev, List<int> list) => max(prev, list.reduce(max))),
          sticked.fold(
              0, (int prev, List<int> list) => max(prev, list.reduce(max))));

      final dX = defaultWidth / entered.length; // Delta X
      final dY = (defaultHeight - gridLineSize) / maxValue; // Delta Y
      final skip = (entered.length / defaultWidth).ceil();
      final gridx = pow(2,
              logN(2, gridMinSize / (defaultWidth / entered.length)).ceil()) *
          (defaultWidth / entered.length);

      // Draw grid.
      ctx.save();
      ctx.lineWidth = 1;
      ctx.setStrokeColorRgb(85, 85, 85);
      for (var x = 0; x < defaultWidth; x += gridx) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, defaultHeight);
        ctx.stroke();
      }
      ctx.restore();

      // Draw all lines.
      ctx.save();
      ctx.lineWidth = gridLineSize;
      _drawGraphLines(dX, dY, skip, entered);
      ctx.lineWidth = 1;
      _drawGraphLines(dX, dY, skip, sticked);
      ctx.restore();
    }

    _scheduleFrame();
  }

  void _drawGraphLines(double dX, double dY, int skip, List<List<int>> data) {
    // Iterate through all particle types and draw their line.
    for (var type = 0; type < colors.length; type++) {
      // Set particle type color.
      ctx.setStrokeColorRgb((colors[type].x * 255).round(),
          (colors[type].y * 255).round(), (colors[type].z * 255).round());

      // Start graph path.
      ctx.beginPath();
      for (var i = 0; i < data.length; i += skip) {
        final thisData = data[i][type];

        // Compute plot x and y.
        //
        // Note that 1 is subtracted to y so that lines at y = 0 with
        // line size = 2 are fully displayed.
        final x = i * dX;
        var y = defaultHeight - thisData * dY - 1;

        // Displace y if there are other lines on this coordinate.
        //
        // There is a nasty exception where two lines that go in a different
        // direction cross each other. This case should be discarded.
        if (data.length > lineDeltaDistance && i > lineDeltaDistance) {
          for (var t = type + 1; t < colors.length; t++) {
            final delta = (data[i][t] - data[i - lineDeltaDistance][t]) -
                (thisData - data[i - lineDeltaDistance][type]);
            if ((data[i][t] - thisData).abs() * dY < gridLineSize &&
                delta.abs() <= lineDeltaThreshold) {
              // Note that the line size is subtracted because of the 2D
              // graphics coordinate system.
              y -= gridLineSize;
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

  /// Schedule a new render cycle.
  void _scheduleFrame() {
    window.requestAnimationFrame((num time) {
      redraw();
    });
  }
}

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

  // Number of datapoints to determine line delta.
  static const lineDeltaDistance = 100;

  // Delta threshold untill lines are stacked.
  static const lineDeltaThreshold = 5;

  /// Rendering canvas
  @override
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
  /// TODO: increase performance.
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

      // Compute drawing parameters.
      final dX = defaultWidth / entered.length; // Delta X
      final dY = (defaultHeight - gridLineSize) / maxValue; // Delta Y
      final skip = (entered.length / defaultWidth).ceil();
      final gridx = pow(2,
              logN(2, gridMinSize / (defaultWidth / entered.length)).ceil()) *
          (defaultWidth / entered.length);

      ctx.save();
      ctx.lineWidth = 1;

      // Draw grid lines.
      ctx.setStrokeColorRgb(85, 85, 85);
      for (var x = 0; x < defaultWidth; x += gridx) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, defaultHeight);
        ctx.stroke();
      }

      ctx.restore();
      ctx.save();
      ctx.lineWidth = gridLineSize;

      // Draw entered count lines.
      _drawGraphLines(dX, dY, skip, entered, (int type) {
        ctx.setStrokeColorRgb((colors[type].x * 255).round(),
            (colors[type].y * 255).round(), (colors[type].z * 255).round());
        ctx.stroke();
      });

      // Draw sticked count lines.
      _drawGraphLines(dX, dY, skip, sticked, (int type) {
        ctx.setStrokeColorRgb((colors[type].x * 255).round(),
            (colors[type].y * 255).round(), (colors[type].z * 255).round());
        ctx.stroke();
        ctx.lineWidth = 1;
        ctx.setStrokeColorRgb(0, 0, 0);
        ctx.stroke();
      });

      ctx.restore();
    }

    _scheduleFrame();
  }

  void _drawGraphLines(double dX, double dY, int skip, List<List<int>> data,
      void stroke(int type)) {
    // Iterate through all particle types and draw their line.
    for (var type = 0; type < colors.length; type++) {
      // Start graph path.
      ctx.beginPath();
      var firstPoint = true;
      for (var i = 0; i < data.length; i += skip) {
        final thisData = data[i][type];

        // Skip if thisData == 0, this prevents the drawing of irrelevant lines.
        if (firstPoint && thisData == 0) {
          continue;
        }

        // Compute plot x and y.
        final x = gridLineSize / 2 + i * dX;
        var y =
            gridLineSize / 2 + (defaultHeight - gridLineSize) - thisData * dY;

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

        if (firstPoint) {
          ctx.moveTo(x, y);
          firstPoint = false;
        } else {
          ctx.lineTo(x, y);
        }
      }

      // Draw the line.
      ctx.save();
      stroke(type);
      ctx.restore();
    }
  }

  /// Schedule a new render cycle.
  void _scheduleFrame() {
    window.requestAnimationFrame((num time) {
      redraw();
    });
  }
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

class ParticleGraph extends CustomElement {
  static const defaultWidth = 330;
  static const defaultHeight = 250;
  static const maxDataPoints = 330;

  /// Rendering canvas
  final CanvasElement node;

  /// 2D rendering context
  CanvasRenderingContext2D ctx;

  /// Line colors
  final List<Vector3> colors = new List();

  /// Entered particle count
  final List<List<int>> entered = new List();

  /// Sticked particle count
  final List<List<int>> sticked = new List();

  ParticleGraph() : node = new CanvasElement() {
    node.width = defaultWidth;
    node.height = defaultHeight;
    ctx = node.getContext('2d');
  }

  /// Add data point
  void addDataPoints(Uint32List _entered, Uint32List _sticked) {
    entered.add(new List<int>.from(_entered));
    sticked.add(new List<int>.from(_sticked));

    if (node.clientWidth > 0) {
      redraw();
    }
  }

  /// Redraw
  void redraw() {
    ctx.rect(0, 0, defaultWidth, defaultHeight);
    ctx.setFillColorRgb(85, 85, 85);
    ctx.fill();
  }
}

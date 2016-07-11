// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:bromium/renderer.dart';
import 'package:bromium/engine.dart';

import 'demos/redblue.dart';

void main() {
  var simulation = createRedBlueDemo();
  var engine = new BromiumEngine(simulation);

  // Setup WebGL renderer.
  var canvas = document.querySelector('#bromium-canvas') as CanvasElement;
  canvas.width = document.body.clientWidth;
  canvas.height = (canvas.width / 5 * 2).round();
  var renderer = new BromiumWebGLRenderer(engine, canvas);
  renderer.focus(simulation.particlesBoundingBox());
  renderer.start();

  // Bind events.
  document.querySelector('#run-simulation').onClick.listen((_) {
    engine.run();
  });
  document.querySelector('#pause-simulation').onClick.listen((_) {
    engine.pause();
  });
  document.querySelector('#toggle-isolates').onClick.listen((_) async {
    // Isolates are not yet implemented.
  });
  document.querySelector('#print-benchmark').onClick.listen((_) {
    engine.printBenchmarks();
  });
}

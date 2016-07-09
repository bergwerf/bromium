// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:bromium/renderer.dart';
import 'package:bromium/engine.dart';

import 'demos/enzyme.dart';

void main() {
  var simulation = createEnzymeDemo();
  var engine = new BromiumEngine(simulation);

  // Setup WebGL renderer.
  var canvas = document.querySelector('#bromium-canvas') as CanvasElement;
  var renderer = new BromiumWebGLRenderer(engine, canvas);
  renderer.focus(simulation.particlesBoundingBox());
  renderer.start();

  // Bind events.
  /*document.querySelector('#run-simulation').onClick.listen((_) {
    engine.run();
  });
  document.querySelector('#pause-simulation').onClick.listen((_) {
    engine.pause();
  });
  document.querySelector('#toggle-isolates').onClick.listen((_) async {
    if (renderer.runSimulationInline) {
      renderer.runSimulationInline = false;
      engine.restartIsolate();
    } else {
      await engine.killIsolate();
      renderer.runSimulationInline = true;
    }
  });
  document.querySelector('#print-benchmark').onClick.listen((_) {
    engine.printBenchmarks();
  });*/
}

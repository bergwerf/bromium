// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:bromium/engine.dart';
import 'package:bromium/renderer.dart';

import '../src/devtools.dart' as console;
import 'redblue.dart';
import 'enzyme.dart';
import 'transport.dart';

void main() {
  // Setup logging.
  console.setupLogging();

  // Create engine.
  var engine = new BromiumEngine(
      inIsolate: !window.navigator.userAgent.contains('Dart'));

  // Setup WebGL renderer.
  var canvas = document.querySelector('#bromium-canvas') as CanvasElement;
  canvas.width = document.body.clientWidth;
  canvas.height = (canvas.width / 5 * 2).round();
  var renderer = new BromiumWebGLRenderer(engine, canvas);

  // Bind events.
  final SelectElement simulationSelector =
      document.querySelector('#simulation-select');
  simulationSelector.onChange.listen((_) async {
    await engine.pause();

    var simulation;
    switch (simulationSelector.value) {
      case 'redblue-1m':
        simulation = createRedBlueDemo(500000, 500000, .002);
        break;
      case 'redblue-100k':
        simulation = createRedBlueDemo(50000, 50000, .006);
        break;
      case 'redblue-10k':
        simulation = createRedBlueDemo(5000, 5000, .01);
        break;
      case 'enzyme':
        simulation = createEnzymeDemo();
        break;
      case 'transport':
        simulation = createTransportDemo();
        break;
    }

    if (simulation != null) {
      var bbox = simulation.particlesBoundingBox();
      await engine.loadSimulation(simulation);
      renderer.focus(bbox);
      renderer.start();
    }
  });

  document.querySelector('#resume-simulation').onClick.listen((_) {
    engine.resume();
  });
  document.querySelector('#pause-simulation').onClick.listen((_) {
    engine.pause();
  });
  document.querySelector('#toggle-isolates').onClick.listen((_) async {
    if (engine.inIsolate) {
      engine.switchToMainThread();
    } else {
      engine.switchToIsolate();
    }
  });
  document.querySelector('#print-benchmark').onClick.listen((_) {
    engine.printBenchmarks();
  });
}

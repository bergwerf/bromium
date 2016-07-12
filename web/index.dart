// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:bromium/engine.dart';
import 'package:bromium/renderer.dart';
import 'package:logging/logging.dart';

import 'devtools.dart' as console;
import 'demos/redblue.dart';
import 'demos/enzyme.dart';

void main() {
  // Setup logging.
  var logColor = {
    Level.FINEST.value: 'black',
    Level.FINER.value: 'black',
    Level.FINE.value: 'black',
    Level.CONFIG.value: 'gray',
    Level.INFO.value: 'green',
    Level.WARNING.value: 'orange',
    Level.SEVERE.value: 'orangered',
    Level.SHOUT.value: 'red'
  };
  var groupStack = [];

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    if (rec.message.startsWith('group: ')) {
      console.group('${rec.loggerName}.${rec.message.substring(7)}');
      groupStack.add(rec.loggerName);
    } else if (rec.message == 'groupEnd') {
      console.groupEnd();
      groupStack.removeLast();
    } else {
      if (groupStack.isNotEmpty && rec.loggerName == groupStack.last) {
        console.print('${rec.message}', color: logColor[rec.level.value]);
      } else {
        console.print('[${rec.loggerName}] ${rec.message}',
            color: logColor[rec.level.value]);
      }

      if (rec.error != null) {
        console.error(rec.error);
      }
    }
  });

  // Create engine.
  var engine = new BromiumEngine();

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
    renderer.pause();

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
    }

    if (simulation != null) {
      var bbox = simulation.particlesBoundingBox();
      await engine.loadSimulation(simulation);
      renderer.focus(bbox);
      renderer.start();
    }
  });

  document.querySelector('#run-simulation').onClick.listen((_) {
    engine.run();
  });
  document.querySelector('#pause-simulation').onClick.listen((_) {
    engine.pause();
  });
  document.querySelector('#toggle-isolates').onClick.listen((_) async {
    // First the isolate has to compress the simulation and send it back up.
  });
  document.querySelector('#print-benchmark').onClick.listen((_) {
    engine.printBenchmarks();
  });
}

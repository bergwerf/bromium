// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:async';

import 'ui/ui.dart';
import 'devtools.dart' as console;

Future main() async {
  // Setup UI.
  setupUi();

  // Setup logging.
  console.setupLogging();

  // Create engine.
  /*var engine = new BromiumEngine();

  // Setup WebGL renderer.
  var canvas = document.querySelector('#bromium-canvas') as CanvasElement;
  var renderer = new BromiumWebGLRenderer(engine, canvas);*/
}

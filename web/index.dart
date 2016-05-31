// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:bromium/bromium.dart';

void main() {
  var canvas = document.querySelector('#bromium-canvas') as CanvasElement;
  var engine = new BromiumEngine();
  var renderer = new BromiumRenderer(engine, canvas);
  renderer.start();
}

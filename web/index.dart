// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:bromium/bromium.dart';
import 'package:bromium/webgl_renderer.dart';
import 'package:vector_math/vector_math.dart';
import 'package:color/color.dart';

void main() {
  var canvas = document.querySelector('#bromium-canvas') as CanvasElement;

  // Create engine and load some presets.
  var engine = new BromiumEngine();
  engine.addParticle('A', 0.01, RgbColor.namedColors['red']);
  engine.addParticle('B', 0.01, RgbColor.namedColors['blue']);
  engine.addCompound(
      'C', 'A', 'B', 0.02, 0.5, 0.001, RgbColor.namedColors['green']);

  engine.allocateParticles([
    new ParticleSet('A', 5000,
        new BoxDomain(new Vector3(.0, .0, .0), new Vector3(1.0, 1.0, 1.0))),
    new ParticleSet('B', 5000,
        new BoxDomain(new Vector3(.0, .0, .0), new Vector3(-1.0, 1.0, 1.0)))
  ]);

  // Bootstrap WebGL renderer.
  var renderer = new BromiumWebGLRenderer(engine, canvas);
  renderer.start();
}

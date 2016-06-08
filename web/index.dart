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

  // Create engine and allocate some particles.
  var engine = new BromiumEngine();
  var particles = new ParticleDict()
    ..addParticle('A', 0.050, [], RgbColor.namedColors['red'])
    ..addParticle('B', 0.050, [], RgbColor.namedColors['blue'])
    ..addParticle('C', 0.025, ['B', 'A'], RgbColor.namedColors['white']);

  var scene = [
    new ParticleSet(particles['A'], 10000,
        new CuboidDomain(new Vector3(.0, .0, .0), new Vector3(1.0, 1.0, 1.0))),
    new ParticleSet(particles['B'], 10000,
        new CuboidDomain(new Vector3(.0, .0, .0), new Vector3(-1.0, 1.0, 1.0)))
  ];

  var bindReactions = [
    new BindReaction(particles['A'], particles['B'], particles['C'], 0.02)
  ];

  var membranes = [
    new Membrane(
        new CuboidDomain(new Vector3(1.0, .0, .0), new Vector3(2.0, 1.0, 1.0)),
        [particles['C']],
        [])
  ];

  engine.allocateParticles(particles, scene, bindReactions, membranes,
      useIntegers: true, voxelsPerUnit: 50);

  // Bootstrap WebGL renderer.
  var renderer = new BromiumWebGLRenderer(engine, canvas);
  renderer.start();
}

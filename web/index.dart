// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:bromium/bromium.dart';
import 'package:bromium/webgl_renderer.dart';
import 'package:color/color.dart';

void main() {
  var canvas = document.querySelector('#bromium-canvas') as CanvasElement;

  // Setup voxel space.
  var space = new VoxelSpace(0.01);

  // Setup particle dictionary with some particles.
  var particles = new ParticleDict()
    ..addParticle('A', space.utov(.05), [], new RgbColor.name('red'))
    ..addParticle('B', space.utov(.05), [], new RgbColor.name('blue'))
    ..addParticle('C', space.utov(.02), ['B', 'A'], new RgbColor.name('white'));

  // Define particle sets.
  var particleSets = [
    new ParticleSet(
        particles.particle('A'),
        5000,
        new CuboidDomain(
            space.point(1.0, 0.0, 0.0), space.point(2.0, 1.0, 1.0))),
    new ParticleSet(
        particles.particle('B'),
        5000,
        new CuboidDomain(
            space.point(-1.0, 0.0, 0.0), space.point(-2.0, 1.0, 1.0)))
  ];

  // Define bind reactions.
  var bindReactions = [
    new BindReaction(particles.particle('A'), particles.particle('B'),
        particles.particle('C'), space.utov(0.005), 1.0)
  ];

  // Define membranes.
  var membranes = [
    new Membrane(
        new CuboidDomain(
            space.point(-10.0, -10.0, -1.0), space.point(10.0, 10.0, -.01)),
        [particles.particle('C')],
        [particles.particle('A'), particles.particle('B')])
  ];

  // Setup simulation engine.
  var engine = new BromiumEngine();
  engine.allocateParticles(
      space, particles, particleSets, bindReactions, membranes);

  // Setup WebGL renderer.
  var renderer = new BromiumWebGLRenderer(engine, canvas);
  var sceneDimensions = engine.computeSceneDimensions();
  renderer.resetCamera(
      sceneDimensions.item1, sceneDimensions.item2, space.depth);
  renderer.reloadMembranes();
  renderer.start();
}

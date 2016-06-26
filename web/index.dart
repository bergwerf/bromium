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
        10000,
        new EllipsoidDomain(space.point(1.0, .0, .0), space.utov(0.5),
            space.utov(0.5), space.utov(0.5))),
    new ParticleSet(
        particles.particle('B'),
        10000,
        new EllipsoidDomain(space.point(-1.0, .0, .0), space.utov(0.5),
            space.utov(0.5), space.utov(0.5)))
  ];

  // Define bind reactions.
  var bindReactions = [
    new BindReaction(particles.particle('A'), particles.particle('B'),
        particles.particle('C'), 1.0)
  ];

  // Define membranes.
  var membranes = [
    new Membrane(
        new EllipsoidDomain(space.point(0.0, 0.0, 0.0), space.utov(3.0),
            space.utov(2.0), space.utov(3.0)),
        {
          particles.particle('A'): 0.0,
          particles.particle('B'): 0.0,
          particles.particle('C'): 0.0
        },
        {
          particles.particle('A'): 0.0,
          particles.particle('B'): 0.0,
          particles.particle('C'): 1.0
        }),
    new Membrane(
        new BoxDomain(
            space.point(-5.0, -5.0, -5.0), space.point(5.0, 5.0, 5.0)),
        {
          particles.particle('A'): 0.0,
          particles.particle('B'): 0.0,
          particles.particle('C'): 0.0
        },
        {
          particles.particle('A'): 0.0,
          particles.particle('B'): 0.0,
          particles.particle('C'): 0.0
        })
  ];

  // Setup simulation engine.
  var engine = new BromiumEngine();
  engine.loadSimulation(
      space, particles, particleSets, bindReactions, membranes);

  // Setup WebGL renderer.
  var renderer = new BromiumWebGLRenderer(engine, canvas);
  var sceneDimensions = engine.computeSceneDimensions();
  renderer.resetCamera(
      sceneDimensions.item1, sceneDimensions.item2, space.depth);
  renderer.start();
  engine.restartIsolate();

  // Bind #run-simulation to renderer.runSimulation = true.
  document.querySelector('#run-simulation').onClick.listen((_) {
    renderer.runSimulation = true;
    engine.resumeIsolate();
  });

  // Bind #pause-simulation to renderer.runSimulation = false.
  document.querySelector('#pause-simulation').onClick.listen((_) {
    renderer.runSimulation = false;
    engine.pauseIsolate();
  });

  // Toggle isolates for simulations.
  document.querySelector('#toggle-isolates').onClick.listen((_) async {
    if (renderer.runSimulationInline) {
      renderer.runSimulationInline = false;
      engine.restartIsolate();
    } else {
      await engine.killIsolate();
      renderer.runSimulationInline = true;
    }
  });

  // Bind #print-benchmark to engine.benchmark.printAllMeasurements().
  document.querySelector('#print-benchmark').onClick.listen((_) {
    engine.printBenchmarks();
  });
}

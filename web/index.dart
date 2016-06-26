// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

import 'package:bromium/bromium.dart';
import 'package:bromium/webgl_renderer.dart';
import 'package:color/color.dart';

void main() {
  var canvas = document.querySelector('#bromium-canvas') as CanvasElement;

  // Setup voxel space
  var space = new VoxelSpace(0.05);

  // Simulation variables.
  var nParticlesGrowth = 1200;
  var nNutrients = 10000;
  var nEnzymes = 5000;
  var cellA = space.utov(4.0), cellB = space.utov(4.0), cellC = space.utov(3.0);

  // Create domains.
  var sceneDomain =
      new BoxDomain(space.point(-5.0, -5.0, -5.0), space.point(5.0, 5.0, 5.0));
  var parentCellDomain = new EllipsoidDomain(
      space.point(0.0, 0.0, 0.0), cellA / 2, cellB / 2, cellC / 2);

  // Setup particle dictionary with some particles.
  var r = space.utov(.05);
  var red = new RgbColor.name('red');
  var blue = new RgbColor.name('blue');
  var green = new RgbColor.name('green');
  var white = new RgbColor.name('white');

  var particles = new ParticleDict()
    ..addParticle('nutrient', r, [], red)
    ..addParticle('enzyme', r, [], blue)
    ..addParticle('enzyme-n', r, ['enzyme', 'nutrient'], green)
    ..addParticle('enzyme-nn', r, ['enzyme-n', 'nutrient'], green)
    ..addParticle('nutrient2', r, ['nutrient', 'nutrient'], white);

  // Setup particle sets.
  var particleSets = [
    new ParticleSet(
        particles.particle('nutrient'),
        nNutrients,
        new BoxDomain(sceneDomain.sc, sceneDomain.lc)
          ..addCavity(parentCellDomain))
  ];

  // Setup bind reactions.
  var bindReactions = [
    new BindReaction(particles.particle('nutrient'),
        particles.particle('enzyme'), particles.particle('enzyme-n'), 1.0),
    new BindReaction(particles.particle('nutrient'),
        particles.particle('enzyme-n'), particles.particle('enzyme-nn'), 1.0)
  ];

  // Setup unbind reactions.
  var unbindReactions = [
    new UnbindReaction(particles.particle('enzyme-nn'),
        [particles.particle('enzyme'), particles.particle('nutrient2')], 0.1)
  ];

  // Setup membranes.
  var membranes = [
    new Membrane(parentCellDomain, {
      particles.particle('nutrient'): 1.0,
      particles.particle('nutrient2'): 0.0,
      particles.particle('enzyme'): 0.0,
      particles.particle('enzyme-n'): 0.0,
      particles.particle('enzyme-nn'): 0.0
    }, {
      particles.particle('nutrient'): 0.0,
      particles.particle('nutrient2'): 0.0,
      particles.particle('enzyme'): 0.0,
      particles.particle('enzyme-n'): 0.0,
      particles.particle('enzyme-nn'): 0.0
    }),
    new Membrane(sceneDomain, {
      particles.particle('nutrient'): 0.0,
      particles.particle('nutrient2'): 0.0,
      particles.particle('enzyme'): 0.0,
      particles.particle('enzyme-n'): 0.0,
      particles.particle('enzyme-nn'): 0.0
    }, {
      particles.particle('nutrient'): 0.0,
      particles.particle('nutrient2'): 0.0,
      particles.particle('enzyme'): 0.0,
      particles.particle('enzyme-n'): 0.0,
      particles.particle('enzyme-nn'): 0.0
    })
  ];
  var parentCell = 0;

  // Setup triggers.
  var triggers = [
    new Trigger([
      new ParticleCountCondition.less(
          nParticlesGrowth, particles.particle('nutrient'), parentCell)
    ], [
      new GrowEllipsoid(
          parentCell,
          particles.particle('nutrient'),
          nParticlesGrowth,
          cellA / 2,
          cellB / 2,
          cellC / 2,
          cellA,
          cellB,
          cellC)
    ]),
    new Trigger.once([
      new ParticleCountCondition.greaterOrEqual(
          nParticlesGrowth, particles.particle('nutrient'), parentCell)
    ], [
      new CreateParticlesAction(
          particles.particle('enzyme'), nEnzymes, parentCell)
    ])
  ];

  // Setup simulation engine.
  var engine = new BromiumEngine();
  engine.loadSimulation(space, particles, particleSets, bindReactions,
      unbindReactions, membranes, triggers, nEnzymes);

  // Setup WebGL renderer.
  var renderer = new BromiumWebGLRenderer(engine, canvas);
  var sceneDimensions = engine.computeSceneDimensions();
  renderer.resetCamera(
      sceneDimensions.item1, sceneDimensions.item2, space.depth);
  //renderer.runSimulationInline = true;
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

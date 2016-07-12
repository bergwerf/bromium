// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:bromium/math.dart';
import 'package:bromium/structs.dart';
import 'package:vector_math/vector_math.dart';

/// Diffusion of red and blue particles, a classic stress test.
Simulation createRedBlueDemo(int na, int nb, double r) {
  // Setup particle dictionary.
  var p = new Index<ParticleType>();
  p['red'] = new ParticleType(Colors.red, 0.01, r);
  p['blue'] = new ParticleType(Colors.blue, 0.01, r);

  // Setup simulation.
  var simulation = new Simulation(p.data, [], []);
  simulation.addRandomParticles(
      p['red'],
      new AabbDomain(new Aabb3.minMax(
          new Vector3(.0, .0, .0), new Vector3(1.0, 1.0, 1.0))),
      na);
  simulation.addRandomParticles(
      p['blue'],
      new AabbDomain(new Aabb3.minMax(
          new Vector3(-1.0, .0, .0), new Vector3(.0, 1.0, 1.0))),
      nb);
  return simulation;
}

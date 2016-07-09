// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:bromium/math.dart';
import 'package:bromium/structs.dart';
import 'package:vector_math/vector_math.dart';

/// Diffusion of red and blue particles
///
/// This is a classic stress test for the optimization of the random motion
/// code. The fastest way to apply random motion is to walk through a
/// Float32List view. The 'clean' method is about twice as slow. However it can
/// easily handle about 200k particles, which is way beyond the limit imposed by
/// reaction kinetics.
Simulation createRedBlueDemo() {
  // Setup particle dictionary.
  var p = new Index<ParticleType>();
  p['red'] = new ParticleType(Colors.red, 0.05, 0.02);
  p['blue'] = new ParticleType(Colors.blue, 0.05, 0.02);

  // Setup simulation.
  var simulation = new Simulation(p.data, [], []);
  simulation.addRandomParticles(
      p['red'],
      new AabbDomain(new Aabb3.minMax(
          new Vector3(.0, .0, .0), new Vector3(1.0, 1.0, 1.0))),
      100000);
  simulation.addRandomParticles(
      p['blue'],
      new AabbDomain(new Aabb3.minMax(
          new Vector3(-1.0, .0, .0), new Vector3(.0, 1.0, 1.0))),
      100000);
  return simulation;
}

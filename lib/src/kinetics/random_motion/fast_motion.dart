// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Faster algorithm for particle random motion when there are no membranes.
void particlesRandomMotionFast(Simulation sim) {
  var rng = new Random();
  var stepRadius = new List<double>.generate(
      sim.particleTypes.length, (int i) => sim.particleTypes[i].stepRadius);
  for (var particle in sim.particles) {
    final r = stepRadius[particle.type];
    final vec = particle.position.storage;
    vec[0] += (rng.nextDouble() - .5) * r;
    vec[1] += (rng.nextDouble() - .5) * r;
    vec[2] += (rng.nextDouble() - .5) * r;
  }
}

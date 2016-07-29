// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

var types = new Uint32List.fromList(new List<int>.filled(1000000, 0));

/// Faster algorithm for particle random motion when there are no membranes.
void particlesRandomMotionFast(Simulation sim) {
  var rng = new Random();
  var view = new Float32List.view(sim.buffer, sim.particlesOffset,
      sim.particles.length * Particle.floatCount);

  final motion = new Vector3.zero();
  for (var p = 0, i = 0; i < view.length; p++, i += 4) {
    randomSphericalVector3(rng, motion);
    final r = sim.particles[p].speed;
    view[i++] += motion.x * r;
    view[i++] += motion.y * r;
    view[i++] += motion.z * r;
  }
}

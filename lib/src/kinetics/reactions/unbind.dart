// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Randomly unbind particles.
void applyUnbindReactions(Simulation sim) {
  var rng = new Random();
  for (var r in sim.info.unbindReactions) {
    for (var p = 0; p < sim.buffer.nParticles - sim.buffer.nInactive; p++) {
      if (sim.buffer.pType[p] == r.particleA && rng.nextDouble() < r.p) {
        sim.unbindParticles(p, r.products);
      }
    }
  }
}

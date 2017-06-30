// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

void reactionsUnbindRandom(Simulation sim) {
  // Build convenient unbind list.
  final unbind = new Map<int, List<Tuple2<int, double>>>();
  for (var i = 0; i < sim.unbindReactions.length; i++) {
    final r = sim.unbindReactions[i];
    unbind.putIfAbsent(r.particleA.type, () => new List<Tuple2<int, double>>());
    unbind[r.particleA.type].add(new Tuple2<int, double>(i, r.probability));
  }

  // Iterate through all particles.
  final rng = new Random();
  for (var i = 0; i < sim.particles.length; i++) {
    final type = sim.particles[i].type;
    if (unbind.containsKey(type)) {
      for (final r in unbind[type]) {
        if (rng.nextDouble() < r.item2) {
          sim.unbindParticle(i, sim.unbindReactions[r.item1].products);

          i--; // this particle was removed or replaced.
          // (in both cases this index has to be re-evaluated)

          break;
        }
      }
    }
  }
}

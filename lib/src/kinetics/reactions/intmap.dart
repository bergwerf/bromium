// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// A [BromiumKineticsAlgorithm] implementation that uses an integer Map to
/// efficiently connect all particles to a voxel hash (and find nearby
/// particles).
///
/// This algorithms takes about 5k/6k microseconds per cycle with 10.000
/// particles and one bind reaction.
void computeReactionsWithIntMap(Simulation sim) {
  // Temporary data structures
  var pos = sim.buffer.pCoords;
  var tree = new Map<int, List<int>>();

  // Random number generator.
  var rng = new Random();

  // Populate tree.
  for (var i = 0, j = 0; i < sim.buffer.nParticles; i++, j += 3) {
    var key = sim.info.space
        .voxelAddress(pos[j], pos[j + 1], pos[j + 2], sim.buffer.pType[i]);
    tree.putIfAbsent(key, () => new List<int>());
    tree[key].add(i);
  }

  for (var i = 0, j = 0; i < sim.buffer.nParticles; i++, j += 3) {
    OUTER: for (var ri = 0; ri < sim.info.bindReactions.length; ri++) {
      var r = sim.info.bindReactions[ri];

      // Check if this particle is the A particle in this bind reaction.
      if (sim.buffer.pType[i] == r.particleA) {
        // If so, look for nearby particles. It is possible to look for more
        // distant particles by iterating through multiple voxels (this was
        // previously implemented using an array of voxel offsets), but
        // properly setting up reaction probabilities and voxels size should
        // make this unnecessary.
        var pkey = sim.info.space
            .voxelAddress(pos[j], pos[j + 1], pos[j + 2], r.particleB);
        if (tree.containsKey(pkey)) {
          // Iterate through this voxel.
          for (var p in tree[pkey]) {
            // In case of an A + A -> B reaction p could be the same as i.
            if (p == i) {
              continue;
            }

            // There are two conditions to proceed:
            // 1. Both particles must have fully matching parent membranes.
            // 2. Randomly decide based on the reaction probability.
            if (sim.buffer.matchParentMembranes(i, p) &&
                rng.nextDouble() < r.p) {
              // Remove particle i and p from the tree.
              var ikey = sim.info.space
                  .voxelAddress(pos[j], pos[j + 1], pos[j + 2], r.particleB);
              tree[ikey].remove(i);
              tree[pkey].remove(p);

              // Bind the particles.
              sim.bindParticles(i, p, r.particleC);

              // Particle i is bound so no further reaction is possible in
              // this cycle.
              break OUTER;
            }
          }
        }
      }
    }
  }
}

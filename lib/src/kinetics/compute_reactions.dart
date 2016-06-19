// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Generic interface for building a kinetics algorithm.
typedef void BromiumKineticsAlgorithm(BromiumData data);

/// An [BromiumKineticsAlgorithm] implementation using a Minimal Perfect Hash
/// Function that maps all voxel addressses to a unique 64bit integer.
void _computeKinetics(BromiumData data) {
  // Temporary data structures
  var pos = data.particlePosition;
  var tree = new Map<int, List<int>>();

  // Random number generator.
  var rng = new Random();

  // Populate tree.
  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    var key = data.space
        .voxelAddress(pos[j], pos[j + 1], pos[j + 2], data.particleType[i]);
    tree.putIfAbsent(key, () => new List<int>());
    tree[key].add(i);
  }

  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    OUTER: for (var ri = 0; ri < data.bindReactions.length; ri++) {
      var r = data.bindReactions[ri];

      // Check if this particle is the A particle in this bind reaction.
      if (data.particleType[i] == r.particleA) {
        // If so, look for nearby particles. It is possible to look for more
        // distant particles by iterating through multiple voxels (this was
        // previously implemented using an array of voxel offsets), but
        // properly setting up reaction probabilities and voxels size should
        // make this unnecessary.
        var pkey = data.space
            .voxelAddress(pos[j], pos[j + 1], pos[j + 2], r.particleB);
        if (tree.containsKey(pkey)) {
          // Iterate through this voxel.
          for (var p in tree[pkey]) {
            // In case of an A + A -> B reaction p could be the same as i.
            if (p == i) {
              continue;
            }

            // Randomly decide to proceed the reaction.
            if (rng.nextDouble() < r.p) {
              // Remove particle i and p from the tree.
              var ikey = data.space
                  .voxelAddress(pos[j], pos[j + 1], pos[j + 2], r.particleB);
              tree[ikey].remove(i);
              tree[pkey].remove(p);

              // Bind the particles.
              data.bindParticles(i, p, r.particleC);

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

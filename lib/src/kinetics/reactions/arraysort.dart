// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Voxel hash and index information for one particle.
class _HIParticle {
  final int i, hash;
  _HIParticle(this.i, this.hash);
}

/// A [BromiumKineticsAlgorithm] implementation that uses a sorted voxel hash
/// array to efficiently connect nearby particles.
void computeReactionsWithArraySort(BromiumData data) {
  var rng = new Random();
  var pos = data.particlePosition;
  var addr = new List<_HIParticle>(data.activeParticleCount);

  // Compute hashes.
  for (var i = 0, j = 0; i < data.activeParticleCount; i++, j += 3) {
    addr[i] = new _HIParticle(
        i, data.space.plainVoxelAddress(pos[j], pos[j + 1], pos[j + 2]));
  }

  // Sort addresses.
  addr.sort((_HIParticle a, _HIParticle b) => a.hash - b.hash);

  // Find reactions.
  var currentStreak = 0, previousVoxel = -1;
  var particleTree = new Map<int, List<int>>();
  for (var i = 0; i < addr.length; i++) {
    // If there are multiple particles in this voxel, start building a particle
    // tree.
    if (addr[i].hash != previousVoxel) {
      if (currentStreak > 0) {
        // The previous voxel contained multiple particles which are collected
        // in particleTree. Process these particles.
        //
        // NOTE: this process is inefficient when the particle system is very
        // dence. Perhaps it is possible to better predict if a voxel contains
        // particles that can do potential reactions.
        for (var ri = 0; ri < data.bindReactions.length; ri++) {
          var r = data.bindReactions[ri];

          // Check if the voxel contains particle A and particle B if particle
          // A and B are distinct. Else check if the voxel contains two particle
          // A's.
          if ((r.particleA != r.particleB &&
                  particleTree.containsKey(r.particleA) &&
                  particleTree.containsKey(r.particleB)) ||
              (r.particleA == r.particleB &&
                  particleTree.containsKey(r.particleA) &&
                  particleTree[r.particleA].length > 1)) {
            // Randomly decide to proceed the reaction.
            if (rng.nextDouble() < r.p) {
              // Collect particle indices.
              var aidx = particleTree[r.particleA].removeLast();
              var bidx = particleTree[r.particleB].removeLast();

              // Bind the particles.
              data.bindParticles(aidx, bidx, r.particleC);
            }
          }
        }
      }

      // Update the previous voxel to this voxel and reset the current streak.
      previousVoxel = addr[i].hash;
      currentStreak = 0;
    } else {
      currentStreak++;
      if (currentStreak == 1) {
        particleTree.clear();

        // Add previous particle.
        var prevType = data.particleType[addr[i - 1].i];
        particleTree.putIfAbsent(prevType, () => new List<int>());
        particleTree[prevType].add(addr[i - 1].i);
      }

      // Add current particle.
      var currType = data.particleType[addr[i].i];
      particleTree.putIfAbsent(currType, () => new List<int>());
      particleTree[currType].add(addr[i].i);
    }
  }
}

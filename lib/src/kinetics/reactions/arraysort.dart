// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Voxel hash and index information for one particle.
class _HIParticle {
  final int i, hash;
  _HIParticle(this.i, this.hash);
}

/// Internal function in [computeReactionsWithArraySort] to apply reactions.
void _applyReactionsInParticleTree(Simulation sim, Map<int, List<int>> tree) {
  var rng = new Random();

  // NOTE: this process is inefficient when the particle system is very
  // dence. Perhaps it is possible to better predict if a voxel contains
  // particles that can do potential reactions.
  for (var ri = 0; ri < sim.info.bindReactions.length; ri++) {
    var r = sim.info.bindReactions[ri];

    // Check if the voxel contains particle A and particle B if particle
    // A and B are distinct. Else check if the voxel contains two particle
    // A's.
    if ((r.particleA != r.particleB &&
            tree.containsKey(r.particleA) &&
            tree.containsKey(r.particleB)) ||
        (r.particleA == r.particleB &&
            tree.containsKey(r.particleA) &&
            tree[r.particleA].length > 1)) {
      // Remove particle indices (and collect them as side effect).
      // Note that this still behaves correctly if particleA == particleB.
      var aidx = tree[r.particleA].removeLast();
      var bidx = tree[r.particleB].removeLast();

      // There are two conditions to proceed:
      // 1. Both particles must have fully matching parent membranes.
      // 2. Randomly decide based on the reaction probability.
      if (sim.buffer.matchParentMembranes(aidx, bidx) &&
          rng.nextDouble() < r.p) {
        // Bind the particles.
        sim.bindParticles(aidx, bidx, r.particleC);
      } else {
        // Add both particles back to the tree.
        tree[r.particleB].add(bidx);
        tree[r.particleA].add(aidx);
      }
    }
  }
}

/// A [BromiumKineticsAlgorithm] implementation that uses a sorted voxel hash
/// array to efficiently connect nearby particles.
void computeReactionsWithArraySort(
    Simulation sim, Uint32List sortCache, BromiumBenchmark benchmark) {
  var pos = sim.buffer.pCoords;
  var addr = new List<_HIParticle>(sortCache.length);

  // Compute hashes.
  for (var i = 0, j = 0; i < sortCache.length; i++, j += 3) {
    addr[sortCache[i]] = new _HIParticle(
        i, sim.info.space.plainVoxelAddress(pos[j], pos[j + 1], pos[j + 2]));
  }

  // Sort addresses.
  benchmark.start('array sort');
  addr.sort((_HIParticle a, _HIParticle b) => a.hash - b.hash);
  benchmark.end('array sort');

  // Find reactions.
  var currentStreak = 0, previousVoxel = -1;
  var particleTree = new Map<int, List<int>>();
  for (var i = 0; i < addr.length; i++) {
    // If there are multiple particles in this voxel, start building a particle
    // tree.
    if (addr[i].hash != previousVoxel) {
      if (currentStreak > 0) {
        // The previous voxel contained multiple particles which are collected
        // in particleTree.
        _applyReactionsInParticleTree(sim, particleTree);
      }

      // Update the previous voxel to this voxel and reset the current streak.
      previousVoxel = addr[i].hash;
      currentStreak = 0;
    } else {
      currentStreak++;
      if (currentStreak == 1) {
        particleTree.clear();

        // Add previous particle.
        var prevType = sim.buffer.pType[addr[i - 1].i];
        particleTree.putIfAbsent(prevType, () => new List<int>());
        particleTree[prevType].add(addr[i - 1].i);
      }

      // Add current particle.
      var currType = sim.buffer.pType[addr[i].i];
      particleTree.putIfAbsent(currType, () => new List<int>());
      particleTree[currType].add(addr[i].i);
    }
  }

  // Update sorting cache.
  for (var i = 0; i < addr.length; i++) {
    sortCache[addr[i].i] = i;
  }
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

// Voxels per unit when using the fast voxel reaction algorithm.
const fastVoxelReactionVPU = 10;

class Voxel {
  final int i, n;

  Voxel(this.i, this.n);

  /// Compute a voxel number for the given vector. The vector is multiplied by
  /// the given [vpu] and truncated. The voxel space number fits inside the
  /// ECMA max int (2^53 - 1). The voxel space size is 2^17.
  static int computeNumber(Vector3 vec, int vpu) {
    final x = (vec.x * vpu).truncate() + 65536;
    final y = (vec.y * vpu).truncate() + 65536;
    final z = (vec.z * vpu).truncate() + 65536;
    return 17179869184 * x + 131072 * y + z;
  }
}

class VoxelSortCache extends ReactionAlgorithmCache {
  List<List<int>> order;
}

void reactionsFastVoxel(Simulation sim) {
  var list = new List<List<Voxel>>(sim.particleTypes.length);
  var vpu = fastVoxelReactionVPU;

  // Compute Z-order curve coordinates.
  for (var i = 0; i < sim.particles.length; i++) {
    final p = sim.particles[i];
    if (list[p.type] == null) {
      list[p.type] = new List<Voxel>();
    }

    list[p.type].add(new Voxel(i, Voxel.computeNumber(p.position, vpu)));
  }

  // Sort all lists.
  for (var i = 0; i < list.length; i++) {
    if (list[i] != null) {
      list[i].sort((Voxel a, Voxel b) => a.n - b.n);
    }
  }

  // Iterate through reactions.
  var rng = new Random();
  var reactionQueue = new List<Tuple3<int, int, int>>();
  for (var r in sim.bindReactions) {
    // Skip if one of the particles is not in the simulation.
    if (list[r.particleA] == null || list[r.particleB] == null) {
      continue;
    }

    // Get reactant with smallest number of particles.
    final ab = list[r.particleA].length < list[r.particleB].length;
    final a = ab ? r.particleA : r.particleB;
    final b = ab ? r.particleB : r.particleA;

    // Iterate through reactant a and b simultaneously.
    REACTION: for (var ai = 0, bi = 0; ai < list[a].length; ai++) {
      final vn = list[a][ai].n;

      // Find first b voxel that is equal or larger than the current a voxel.
      while (list[b][bi].n < vn) {
        bi++;

        // If bi is larger than the b list, we can quit this reaction.
        if (bi == list[b].length) {
          break REACTION;
        }
      }

      // Check if the next b voxel is equal to the current a voxel.
      // If so randomly decide to proceed the reaction.
      if (list[b][bi].n == vn && rng.nextDouble() < r.probability) {
        // Queue bind reaction.
        reactionQueue.add(new Tuple3<int, int, int>(
            list[a][ai].i, list[b][bi].i, r.particleC));

        // Move bi forward.
        bi++;

        // If bi is larger than the b list, we can quit this reaction.
        if (bi == list[b].length) {
          break REACTION;
        }
      }
    }
  }

  // Execute reaction queue.
  sim.applyBindReactions(reactionQueue);
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Voxels per unit when using the fast voxel reaction algorithm.
const fastVoxelReactionVPU = 50;

class Voxel {
  final int i, n;

  Voxel(this.i, this.n);

  /// Compute a voxel number for the given vector. The vector is multiplied by
  /// the given [vpu] and truncated. The voxel space number fits inside the
  /// ECMA max int (2^53 - 1). The voxel space size is 2^17. Semi-axis size is
  /// 2^16 = 65536.
  static int computeNumber(Vector3 vec, int vpu) {
    final x = (vec.x * vpu).truncate() + 65536;
    final y = (vec.y * vpu).truncate() + 65536;
    final z = (vec.z * vpu).truncate() + 65536;
    return 17179869184 * x + 131072 * y + z;
  }

  /// Compute z-order number.
  static int computeZNumber(Vector3 vec, int vpu) {
    final x = (vec.x * vpu).truncate();
    final y = (vec.y * vpu).truncate();
    final z = (vec.z * vpu).truncate();
    return interleave3xInt32inUint64(x, y, z);
  }
}

/// Fast bind reaction algorithm
///
/// It has been attempted to use caching to speed up reaction voxel sorting.
/// Z-order curve numbers could be used to better preserve locality. However, it
/// turns out that caching the two dimensional voxel list takes too many extra
/// operations to really speed things up. Parallel sorting might be a more
/// efficient optimization.
///
/// TODO: use direction vector to compute secondary collision probability
/// factor.
void reactionsBindVoxelFast(Simulation sim) {
  final list = new List<List<Voxel>>(sim.particleTypes.length);
  final vpu = fastVoxelReactionVPU;

  // Create voxels.
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
      list[i].sort((a, b) => a.n - b.n);
    }
  }

  // Iterate through reactions.
  final reactionQueue = new List<BindRxnItem>();
  for (var ridx = 0; ridx < sim.bindReactions.length; ridx++) {
    final r = sim.bindReactions[ridx];

    // Skip if one of the particles is not in the simulation.
    if (list[r.particleA.type] == null || list[r.particleB.type] == null) {
      continue;
    }

    // Get reactant with smallest number of particles.
    final ab = list[r.particleA.type].length < list[r.particleB.type].length;
    final a = ab ? r.particleA.type : r.particleB.type;
    final b = ab ? r.particleB.type : r.particleA.type;

    // Iterate through reactant a and b simultaneously.
    REACTION:
    for (var ai = 0, bi = 0; ai < list[a].length; ai++) {
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
      // If this is the case, randomly decide to proceed the reaction.
      //
      // TODO: try to bind with other b particles in the same voxel if this
      // reaction does not proceed.
      final ap = sim.particles[list[a][ai].i];
      final bp = sim.particles[list[b][bi].i];
      if (list[b][bi].n == vn && r.tryReaction(ab ? ap : bp, ab ? bp : ap)) {
        // Queue bind reaction.
        reactionQueue.add(new BindRxnItem(list[a][ai].i, list[b][bi].i, ridx));

        // Remove `ai` and `bi` particles from the lists since they are queued.
        // This prevents duplicate reactions from being queued.
        list[a].removeAt(ai);
        list[b].removeAt(bi);

        // Note that we do not have to increment `bi` since we removed the
        // element at `bi` so the next element is at `bi`.

        // Decrement `ai` so that `ai++` in the next iteration will give the
        // current `ai` (which is the next element index).
        ai--;

        // If `bi` is larger than the `b` list, we can quit this reaction.
        if (bi == list[b].length) {
          break REACTION;
        }
      }
    }
  }

  // Execute reaction queue.
  sim.applyBindReactions(reactionQueue);
}

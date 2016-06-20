// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// A [BromiumKineticsAlgorithm] implementation that uses a sorted voxel hash
/// array to efficiently connect nearby particles.
void computeReactionsWithIntSet(BromiumData data) {
  var pos = data.particlePosition;
  var addr = new List<int>(data.particleType.length);

  // Compute hashes.
  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    addr[i] = data.space.plainVoxelAddress(pos[j], pos[j + 1], pos[j + 2]);
  }

  // Find reactions.
  var addrSet = new Set<int>(), doneSet = new Set<int>();
  for (var i = 0; i < addr.length; i++) {
    // If the current voxel hash exists in the set, multiple voxels exist in
    // this voxel.
    var voxel = addr[i];
    if (!addrSet.contains(voxel)) {
      addrSet.add(voxel);
    } else if (!doneSet.contains(voxel)) {
      // Add this voxel to the done set, and process it.
      doneSet.add(voxel);

      // Search the entire array for this value and build a particle tree.
      var particleTree = new Map<int, List<int>>();
      for (var j = 0; j < addr.length; j++) {
        if (addr[j] == voxel) {
          // Add to particle tree.
          var type = data.particleType[j];
          particleTree.putIfAbsent(type, () => new List<int>());
          particleTree[type].add(j);
        }
      }

      // Apply reactions.
      _applyReactionsInParticleTree(data, particleTree);
    }
  }
}

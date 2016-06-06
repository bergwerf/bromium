// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Generic interface for building a kinetics algorithm.
typedef void BromiumKineticsAlgorithm(BromiumData data);

/// MFHF for [mphfMapKinetics].
int mphfVoxelAddress(int x, int y, int z, int type, int ntypes) {
  return (ntypes * 1000 * 1000) * (x + 500) +
      (ntypes * 1000) * (y + 500) +
      ntypes * (z + 500) +
      type;
}

/// An [BromiumKineticsAlgorithm] implementation using a Minimal Perfect Hash
/// Function that maps all voxel addressses to a unique 64bit integer.
void mphfMapKinetics(BromiumData data) {
  // Temporary data structures
  var voxels = data.useIntegers
      ? data.particleUint16Position
      : new Uint16List(data.particleType.length * 3);
  var tree = new Map<int, List<int>>();

  // Compute voxels (floating point only).
  if (!data.useIntegers) {
    for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
      for (var d = 0; d < 3; d++) {
        voxels[j + d] =
            (data.particleFloatPosition[j + d] * data.voxelsPerUnit).round();
      }
    }
  }

  // Populate tree.
  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    var key = mphfVoxelAddress(
        voxels[j], voxels[j + 1], voxels[j + 2], data.particleType[i], 2);
    tree.putIfAbsent(key, () => new List<int>());
    tree[key].add(i);
  }

  int aIdx = 0; //data.particleLabels.indexOf('A');
  int bIdx = 1; //data.particleLabels.indexOf('B');

  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    if (data.particleType[i] == aIdx) {
      // Find all near particles.
      var nearParticles = new List<int>();
      var key =
          mphfVoxelAddress(voxels[j], voxels[j + 1], voxels[j + 2], bIdx, 2);
      if (tree.containsKey(key)) {
        nearParticles.addAll(tree[key]);
      }

      // If there is a near particle, bind with it.
      if (nearParticles.length > 0) {
        data.particleColor[i * 4] = 0;
        data.particleColor[i * 4 + 1] = 255;
        data.particleColor[nearParticles.first * 4 + 2] = 0;
      }
    }
  }
}

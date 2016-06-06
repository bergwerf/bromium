// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Generic interface for building a kinetics algorithm.
typedef void BromiumKineticsAlgorithm(BromiumData data);

/// Voxel space size (16bit unsigned int max)
///
///     maxUint16 = 2^16 = 65536
///     maxInt64  = 2^63 - 1
///     maxVoxel  = ntypes *
///       (voxelSpaceSize^3 + voxelSpaceSize^2 * voxelSpaceSize^1 + 1)
///     maxTypes  = floor((2^63-1) / (2^(16*3) + 2^(16*2) + 2^(16*1) + 1))
///               = 32767
///
const voxelSpaceSize = 65536;

/// MFHF for [mphfMapKinetics].
///
/// Unsimplified:
///
///     hash = (ntypes * voxelSpaceSize^2) * x +
///            (ntypes * voxelSpaceSize^1) * y +
///            (ntypes * voxelSpaceSize^0) * z +
///            type
///
int mphfVoxelAddress(int x, int y, int z, int type, int ntypes) {
  return ntypes * (4294967296 * x + 65536 * y + z) + type;
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

  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    for (var ri = 0; ri < data.bindReactions.length; ri++) {
      var r = data.bindReactions[ri];

      // Check if this particle is the A particle in this bind reaction.
      if (data.particleType[i] == r.particleA) {
        // If so, collect nearby particles.
        // Note: use pre-calculated voxel groups (spherical shape).
        var nearParticles = new List<int>();
        var key = mphfVoxelAddress(
            voxels[j], voxels[j + 1], voxels[j + 2], r.particleB, 2);
        if (tree.containsKey(key)) {
          nearParticles.addAll(tree[key]);
        }

        // Note: filter using actual separation distance in a float context.

        // If there are near particles, apply a bind reaction.
        if (nearParticles.length > 0) {
          var other = nearParticles.first;

          // 1. Remove the other particle from the simulation.

          // Set position to (0, 0, 0).
          for (var d = 0; d < 3; d++) {
            if (data.useIntegers) {
              data.particleUint16Position[other * 3 + d] = 0;
            } else {
              data.particleFloatPosition[other * 3 + d] = 0.0;
            }
          }

          // Set color to (0, 0, 0, 0).
          for (var c = 0; c < 4; c++) {
            data.particleColor[other * 4 + c] = 0;
          }

          // Bind the particle to the target particle.
          data.particleBonds[other] = i;

          // 2. Change the target particle to the binding product.

          // Set the particle type to the new type.
          data.particleType[i] = r.particleC;

          // Set the particle color to the new color.
          for (var c = 0; c < 4; c++) {
            data.particleColor[i * 4 + c] =
                data.particleColorSettings[r.particleC * 4 + c];
          }
        }
      }
    }
  }
}

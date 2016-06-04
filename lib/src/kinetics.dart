// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Generic interface for building a kinetics algorithm.
typedef void BromiumKineticsAlgorithm(BromiumEngineData data);

/// MFHF for [mphfMapKinetics].
int mphfVoxelAddress(int x, int y, int z, int type, int ntypes) {
  return (ntypes * 1000 * 1000) * (x + 500) +
      (ntypes * 1000) * (y + 500) +
      ntypes * (z + 500) +
      type;
}

/// An [BromiumKineticsAlgorithm] implementation using a Minimal Perfect Hash
/// Function that maps all voxel addressses to a unique 64bit integer.
void mphfMapKinetics(BromiumEngineData data) {
  // Voxel data structures
  var voxel = new Float32List(data.particleType.length * 3);
  var tree = new Map<int, List<int>>();

  // Populate tree.
  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    for (var d = 0; d < 3; d++) {
      voxel[j + d] = data.particlePosition[j + d] / 0.01;
    }

    var vx = voxel[j + 0].round();
    var vy = voxel[j + 1].round();
    var vz = voxel[j + 2].round();

    var key = mphfVoxelAddress(vx, vy, vz, data.particleType[i], 2);

    tree.putIfAbsent(key, () => new List<int>());
    tree[key].add(i);
  }

  int aIdx = data.particleLabels.indexOf('A');
  int bIdx = data.particleLabels.indexOf('B');

  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    if (data.particleType[i] == aIdx) {
      // Append all voxels.
      var nearParticles = new List<int>();
      var vxf = voxel[j + 0].floor();
      var vxc = voxel[j + 0].ceil();
      var vyf = voxel[j + 1].floor();
      var vyc = voxel[j + 1].ceil();
      var vzf = voxel[j + 2].floor();
      var vzc = voxel[j + 2].ceil();
      var nearVx = [
        [vxf, vyf, vzf],
        [vxf, vyf, vzc],
        [vxf, vyc, vzf],
        [vxf, vyc, vzc],
        [vxc, vyf, vzf],
        [vxc, vyf, vzc],
        [vxc, vyc, vzf],
        [vxc, vyc, vzc]
      ];

      for (var v = 0; v < nearVx.length; v++) {
        var key =
            mphfVoxelAddress(nearVx[v][0], nearVx[v][1], nearVx[v][2], bIdx, 2);
        if (tree.containsKey(key)) {
          nearParticles.addAll(tree[key]);
        }
      }

      // If there is a near particle, bind with it.
      if (nearParticles.length > 0) {
        data.particleColor[i * 4] = 0.0;
        data.particleColor[i * 4 + 1] = 1.0;
        data.particleColor[nearParticles.first * 4 + 2] = 0.0;
      }
    }
  }
}

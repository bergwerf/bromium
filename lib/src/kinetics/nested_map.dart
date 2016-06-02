// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// An [BromiumKineticsAlgorithm] implementation using a nested dart:core map.
void nestedMapKinetics(BromiumEngineData data) {
  // Voxel data structures
  var voxel = new List<List<double>>(data.particleType.length);
  var tree = new Map<int, Map<int, Map<int, Map<int, List<int>>>>>();

  // Populate tree.
  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    voxel[i] = [
      data.particlePosition[j + 0] / 0.01,
      data.particlePosition[j + 1] / 0.01,
      data.particlePosition[j + 2] / 0.01
    ];

    var vx = voxel[i][0].round();
    var vy = voxel[i][1].round();
    var vz = voxel[i][2].round();

    tree.putIfAbsent(vx, () => new Map<int, Map<int, Map<int, List<int>>>>());
    tree[vx].putIfAbsent(vy, () => new Map<int, Map<int, List<int>>>());
    tree[vx][vy].putIfAbsent(vz, () => new Map<int, List<int>>());
    tree[vx][vy][vz].putIfAbsent(data.particleType[i], () => new List<int>());
    tree[vx][vy][vz][data.particleType[i]].add(i);
  }

  int aIdx = data.particleLabels.indexOf('A');
  int bIdx = data.particleLabels.indexOf('B');

  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    if (data.particleType[i] == aIdx) {
      // Append all voxels.
      var nearParticles = new List<int>();
      var vxf = voxel[i][0].floor();
      var vxc = voxel[i][0].ceil();
      var vyf = voxel[i][1].floor();
      var vyc = voxel[i][1].ceil();
      var vzf = voxel[i][2].floor();
      var vzc = voxel[i][2].ceil();
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
        if (tree.containsKey(nearVx[v][0]) &&
            tree[nearVx[v][0]].containsKey(nearVx[v][1]) &&
            tree[nearVx[v][0]][nearVx[v][1]].containsKey(nearVx[v][2]) &&
            tree[nearVx[v][0]][nearVx[v][1]][nearVx[v][2]].containsKey(bIdx)) {
          nearParticles
              .addAll(tree[nearVx[v][0]][nearVx[v][1]][nearVx[v][2]][bIdx]);
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

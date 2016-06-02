// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class AvlTreeVoxel {
  /// Voxel x, y, z coordinates and the particle type
  int x, y, z, type;

  /// Particle indices in this voxel
  List<int> particles = new List<int>();

  /// Constructor
  AvlTreeVoxel(this.x, this.y, this.z, this.type);

  /// Comperator
  static int comparator(AvlTreeVoxel a, AvlTreeVoxel b) {
    if (a.x == b.x) {
      if (a.y == b.y) {
        if (a.z == b.z) {
          return a.type.compareTo(b.type);
        } else {
          return a.z.compareTo(b.z);
        }
      } else {
        return a.y.compareTo(b.y);
      }
    } else {
      return a.x.compareTo(b.x);
    }
  }
}

/// An [BromiumKineticsAlgorithm] implementation using an AVL binary tree.
void alvTreeKinetics(BromiumEngineData data) {
  var voxel = new List<List<double>>(data.particleType.length);
  var tree = new AvlTreeSet<AvlTreeVoxel>(comparator: AvlTreeVoxel.comparator);

  // Populate tree.
  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    voxel[i] = [
      data.particlePosition[j + 0] / 0.01,
      data.particlePosition[j + 1] / 0.01,
      data.particlePosition[j + 2] / 0.01
    ];

    var voxelX = voxel[i][0].round();
    var voxelY = voxel[i][1].round();
    var voxelZ = voxel[i][2].round();

    var thisVoxel =
        new AvlTreeVoxel(voxelX, voxelY, voxelZ, data.particleType[i]);
    var ref = tree.lookup(thisVoxel);
    if (ref == null) {
      thisVoxel.particles.add(i);
      tree.add(thisVoxel);
    } else {
      ref.particles.add(i);
    }
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
        var thisVoxel =
            new AvlTreeVoxel(nearVx[v][0], nearVx[v][1], nearVx[v][2], bIdx);
        var ref = tree.lookup(thisVoxel);
        if (ref != null) {
          nearParticles.addAll(ref.particles);
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

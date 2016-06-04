// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:quiver/collection.dart';
import 'package:bromium/bromium.dart';

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
void avlTreeKinetics(BromiumEngineData data) {
  var voxel = new Float32List(data.particleType.length * 3);
  var tree = new AvlTreeSet<AvlTreeVoxel>(comparator: AvlTreeVoxel.comparator);

  // Populate tree.
  for (var i = 0, j = 0; i < data.particleType.length; i++, j += 3) {
    for (var d = 0; d < 3; d++) {
      voxel[j + d] = data.particlePosition[j + d] / 0.01;
    }

    var vx = voxel[j + 0].round();
    var vy = voxel[j + 1].round();
    var vz = voxel[j + 2].round();

    var thisVoxel = new AvlTreeVoxel(vx, vy, vz, data.particleType[i]);
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

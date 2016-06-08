// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Data structure for A + B -> C style reactions information
class BindReaction {
  /// Particle A label
  final int particleA;

  /// Particle B label
  final int particleB;

  /// Particle C label
  final int particleC;

  /// Exact reaction distance
  final double distance;

  /// Voxel group that should be used to collect nearby particles.
  Int16List nearVoxelGroup;

  /// Constructor
  BindReaction(this.particleA, this.particleB, this.particleC, this.distance);

  /// Initialize voxel group
  void initVoxelGroup(int voxelsPerUnit) {
    nearVoxelGroup = computeSphericalVoxelGroup(distance / 2, voxelsPerUnit);
  }
}

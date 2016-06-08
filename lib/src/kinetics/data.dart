// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Public data structure for A + B -> C style reactions
class BindReaction {
  /// Particle A label
  final String particleA;

  /// Particle B label
  final String particleB;

  /// Particle C label
  final String particleC;

  /// Exact reaction distance
  final double distance;

  /// Constructor
  BindReaction(this.particleA, this.particleB, this.particleC, this.distance);
}

/// Internal data structure for A + B -> C style reactions
class _BindReaction {
  /// Particle A index
  final int particleA;

  /// Particle B index
  final int particleB;

  /// Particle C index
  final int particleC;

  /// Exact reaction distance
  final double distance;

  /// Voxel group that should be used to collect nearby particles.
  final Int16List nearVoxelGroup;

  /// Constructor
  _BindReaction(this.particleA, this.particleB, this.particleC, this.distance,
      this.nearVoxelGroup);
}

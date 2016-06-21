// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Class for storing static simulation information.
class SimulationInfo {
  /// Voxel space where the simulation takes place
  final VoxelSpace space;

  /// Particle type information
  final List<ParticleInfo> particleInfo;

  /// Bind reactions (currenly we keep these static).
  final List<BindReaction> bindReactions;

  /// Membrane types (dimensions and permeability are dynamic).
  final List<DomainType> membranes;

  /// Constuctor
  SimulationInfo(
      this.space, this.particleInfo, this.bindReactions, this.membranes);
}

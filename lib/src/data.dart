// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Random walk step size data.
class _RandomWalkStep {
  /// Step size rounded to an odd integer.
  final int oddSize;

  /// oddSize - sub = number between -n and n where n is the step radius.
  final int sub;

  /// Constructor
  _RandomWalkStep(double r)
      : oddSize = r.ceil() * 2 + 1,
        sub = r.ceil();
}

/// Separate class for all data that is used for the simulation computations.
class BromiumData {
  /// Voxel space where the simulation takes place
  final VoxelSpace space;

  /// All membranes in the simulation
  final List<Membrane> membranes;

  /// Bind reaction data
  final List<BindReaction> bindReactions;

  /// Parameters to compute random walk displacements for each type.
  final List<_RandomWalkStep> randomWalkStep;

  /// Type index of each particle
  ///
  /// To inactivate a particle the type is set to -1. Inactive particles should
  /// all be placed at the end of this list so the vertex buffer can be directly
  /// used by glDrawArrays.
  final Int16List particleType;

  /// Position of each particle as a WebGL buffer
  final Uint16List particlePosition;

  /// Color of each particle as a WebGL buffer
  final Uint8List particleColor;

  /// Configured colors for each particle type
  final Uint8List particleTypeColor;

  /// Length of the inactive tail of the particle vertex buffer in number of
  /// particles.
  int inactiveCount = 0;

  /// Final constructor
  BromiumData(
      // Voxel space
      this.space,

      // Membranes and reactions
      this.membranes,
      this.bindReactions,
      this.randomWalkStep,

      // Particle information
      this.particleType,
      this.particlePosition,
      this.particleColor,
      this.particleTypeColor);

  /// Allocate only constructor
  factory BromiumData.allocate(VoxelSpace space, int ntypes, int count,
      List<BindReaction> bindReactions, List<Membrane> membranes) {
    return new BromiumData(
        space,
        membranes,
        bindReactions,
        new List<_RandomWalkStep>(ntypes),

        // Particle type
        new Int16List(count),

        // Particle position
        new Uint16List(count * 3),

        // Particle color
        new Uint8List(count * 4),

        // Particle type color
        new Uint8List(ntypes * 4));
  }

  /// Compute distance between two particles.
  double distanceBetween(int a, int b) {
    var ax = particlePosition[a * 3 + 0];
    var ay = particlePosition[a * 3 + 1];
    var az = particlePosition[a * 3 + 2];
    var bx = particlePosition[b * 3 + 0];
    var by = particlePosition[b * 3 + 1];
    var bz = particlePosition[b * 3 + 2];
    return sqrt(
        (ax - bx) * (ax - bx) + (ay - by) * (ay - by) + (az - bz) * (az - bz));
  }

  /// Bind a particle
  ///
  /// This will effectively swap particle b to the front of the inactive part
  /// of the particle vertex buffer and change particle a to compositeType.
  ///
  /// [a]: first particle
  /// [b]: second particle
  /// [compositeType]: type of the new particle (will be assigned to a)
  void bindParticles(int a, int b, int compositeType) {
    // Inactivate b.
    inactivateParticle(b);

    // Set particle a to compositeType.
    editParticle(a, compositeType);
  }

  /// Unbind particle
  ///
  /// This will effectively activate the front of the inactive part of the
  /// particle vextex buffer and change it into [typeB] while the given
  /// particle is changed into [typeA]. An error is thrown if no inactive
  /// particle exists.
  void unbindParticles(int i, int typeA, int typeB) {
    // Set the given particle to typeA.
    editParticle(i, typeA);

    // Set the first inactive particle.
    int particleB = activateParticle(typeB);

    // Copy the location of the given particle to the typeB particle.
    for (var d = 0; d < 3; d++) {
      particlePosition[particleB * 3 + d] = particlePosition[i * 3 + d];
    }
  }

  /// Compute index of the last active particle (before the tail of inactive
  /// particles).
  int get lastActiveParticleIdx => particleType.length - 1 - inactiveCount;

  /// Compute index of the first inactive particle (front of the tail of
  /// inactive particles).
  int get firstInactiveParticleIdx => particleType.length - inactiveCount;

  /// Inactivate a particle.
  void inactivateParticle(int i) {
    // Copy the last active particle into this particle.
    editParticle(i, particleType[lastActiveParticleIdx]);

    // Inactivate the last active particle.
    particleType[lastActiveParticleIdx] = -1;
    inactiveCount++;
  }

  /// Activate a particle.
  int activateParticle(int type) {
    int i = firstInactiveParticleIdx;
    editParticle(i, type);
    inactiveCount--;
    return i;
  }

  /// Change a particle.
  ///
  /// This will effectively update the color and type of the selected particle.
  void editParticle(int i, int type) {
    // Set type.
    particleType[i] = type;

    // Copy color.
    for (var c = 0; c < 4; c++) {
      particleColor[i * 4 + c] = particleTypeColor[type * 4 + c];
    }
  }
}

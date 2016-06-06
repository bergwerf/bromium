// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Separate class for all data that is used for the simulation computations.
///
/// Optimized according to:
/// https://www.opengl.org/wiki/Vertex_Specification_Best_Practices
class BromiumData {
  /// Simulate using integers
  ///
  /// Simulations with integers run much faster than with floating point data,
  /// but they allow less control. This variable cannot be set during a
  /// simulation. If integers or floating point data is used is set in the
  /// [allocateParticles] method.
  final bool useIntegers;

  /// Number of voxels in 1 unit
  ///
  /// If you are using integers everything is scaled by this so the particle
  /// position is the same as the voxel address.
  final int voxelsPerUnit;

  /// Type index of each particle
  final Uint16List particleType;

  /// Position of each particle as a WebGL buffer
  final Float32List particleFloatPosition;

  /// Unsigned 16bit integer variant of [particlePosition]
  final Uint16List particleUint16Position;

  /// Bind reaction data
  final List<_BindReaction> bindReactions;

  /// Particle bond data
  ///
  /// When particle A + B -> C. One of the two particles becomes the C particle,
  /// and the other one is deactivated. However, when C -> A + B again, this
  /// particle has to be reactivated. This way the particle data buffer does not
  /// have to be resized during the simulation. This list will store to which
  /// particle (index) the inactive particles are connected (-1 for not
  /// connected), so they can be found again later for reuse.
  final Int32List particleBonds;

  /// Color of each particle as a WebGL buffer
  final Uint8List particleColor;

  /// Configured colors for each particle type
  final Uint8List particleColorSettings;

  /// Final constructor
  BromiumData(
      this.useIntegers,
      this.voxelsPerUnit,
      this.particleType,
      this.particleFloatPosition,
      this.particleUint16Position,
      this.particleColor,
      this.particleColorSettings,
      this.particleBonds,
      this.bindReactions);

  /// Allocate only constructor
  factory BromiumData.allocate(bool useIntegers, int voxelsPerUnit, int ntypes,
      int count, List<_BindReaction> bindReactions) {
    return new BromiumData(
        useIntegers,
        voxelsPerUnit,
        new Uint16List(count),
        new Float32List(useIntegers ? 0 : count * 3),
        new Uint16List(useIntegers ? count * 3 : 0),
        new Uint8List(count * 4),
        new Uint8List(ntypes * 4),
        new Int32List(count),
        bindReactions);
  }

  /// Getter to get the particle vertex buffer based on [useIntegers].
  TypedData get particleVertexBuffer =>
      useIntegers ? particleUint16Position : particleFloatPosition;

  /// Getter to get the GL datatype of [particleVextexBuffer].
  int get particleVertexBufferType => useIntegers
      ? gl.RenderingContext.UNSIGNED_SHORT
      : gl.RenderingContext.FLOAT;
}

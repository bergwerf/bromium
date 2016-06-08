// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

// Some webgl constants so that we do not have to depend on dart:web_gl and we
// can run the engine in the stand-alone Dart VM.
const _glFloat = 0x1406;
const _glUnsignedShort = 0x1403;

/// Random walk step size data.
class _RandomWalkStep {
  /// Exact step size (2 * radius)
  double size;

  /// Step size rounded to an odd integer.
  int oddSize;

  /// oddSize - sub = number between -n and n where n is the step radius.
  int sub;

  /// Constructor
  _RandomWalkStep(double r, int voxelsPerUnit)
      : size = r * 2,
        oddSize = (r * voxelsPerUnit).round() * 2 + 1,
        sub = (r * voxelsPerUnit).round();
}

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

  /// Number of particle types
  ///
  /// Used to optimize [mphfVoxelAddress].
  final int ntypes;

  /// Type index of each particle
  ///
  /// To inactivate a particle the type is set to -1. Inactive particles should
  /// all be placed at the end of this list so the vertex buffer can be directly
  /// used by glDrawArrays.
  final Int16List particleType;

  /// Random walk step size per type
  final List<_RandomWalkStep> randomWalkStep;

  /// Position of each particle as a WebGL buffer
  final Float32List particleFloatPosition;

  /// Unsigned 16bit integer variant of [particlePosition]
  final Uint16List particleUint16Position;

  /// Length of the inactive tail of the particle vertex buffer in number of
  /// particles.
  int inactiveCount = 0;

  /// Bind reaction data
  final List<_BindReaction> bindReactions;

  /// Color of each particle as a WebGL buffer
  final Uint8List particleColor;

  /// Configured colors for each particle type
  final Uint8List particleColorSettings;

  /// Final constructor
  BromiumData(
      this.useIntegers,
      this.voxelsPerUnit,
      this.ntypes,
      this.particleType,
      this.randomWalkStep,
      this.particleFloatPosition,
      this.particleUint16Position,
      this.particleColor,
      this.particleColorSettings,
      this.bindReactions);

  /// Allocate only constructor
  factory BromiumData.allocate(bool useIntegers, int voxelsPerUnit, int ntypes,
      int count, List<_BindReaction> bindReactions) {
    return new BromiumData(
        useIntegers,
        voxelsPerUnit,
        ntypes,
        new Int16List(count),
        new List<_RandomWalkStep>(ntypes),
        new Float32List(useIntegers ? 0 : count * 3),
        new Uint16List(useIntegers ? count * 3 : 0),
        new Uint8List(count * 4),
        new Uint8List(ntypes * 4),
        bindReactions);
  }

  /// Getter to get the particle vertex buffer based on [useIntegers].
  TypedData get particleVertexBuffer =>
      useIntegers ? particleUint16Position : particleFloatPosition;

  /// Getter to get the GL datatype of [particleVextexBuffer].
  int get particleVertexBufferType => useIntegers ? _glUnsignedShort : _glFloat;

  /// Compute distance between two particles in units.
  double distanceBetween(int a, int b) {
    if (useIntegers) {
      var ax = particleUint16Position[a * 3 + 0];
      var ay = particleUint16Position[a * 3 + 1];
      var az = particleUint16Position[a * 3 + 2];
      var bx = particleUint16Position[b * 3 + 0];
      var by = particleUint16Position[b * 3 + 1];
      var bz = particleUint16Position[b * 3 + 2];
      return sqrt((ax - bx) * (ax - bx) +
              (ay - by) * (ay - by) +
              (az - bz) * (az - bz)) /
          voxelsPerUnit;
    } else {
      var ax = particleFloatPosition[a * 3 + 0];
      var ay = particleFloatPosition[a * 3 + 1];
      var az = particleFloatPosition[a * 3 + 2];
      var bx = particleFloatPosition[b * 3 + 0];
      var by = particleFloatPosition[b * 3 + 1];
      var bz = particleFloatPosition[b * 3 + 2];
      return sqrt((ax - bx) * (ax - bx) +
          (ay - by) * (ay - by) +
          (az - bz) * (az - bz));
    }
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
      if (useIntegers) {
        particleUint16Position[particleB * 3 + d] =
            particleUint16Position[i * 3 + d];
      } else {
        particleFloatPosition[particleB * 3 + d] =
            particleFloatPosition[i * 3 + d];
      }
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
      particleColor[i * 4 + c] = particleColorSettings[type * 4 + c];
    }
  }
}

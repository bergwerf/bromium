// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Helper class that combines the simulation byte data and the simulation info.
class Simulation {
  /// Static simulation information
  final SimulationInfo info;

  /// Simulation data buffer (can be replaced by externally computed cycles).
  SimulationBuffer buffer;

  /// Constuctor
  Simulation(this.info, this.buffer);

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
      buffer.pCoords[particleB * 3 + d] = buffer.pCoords[i * 3 + d];
    }
  }

  /// Inactivate a particle.
  void inactivateParticle(int i) {
    // Copy the last active particle into this particle.
    editParticle(i, buffer.pType[buffer.lastActiveParticleIdx]);

    // Inactivate the last active particle.
    buffer.pType[buffer.lastActiveParticleIdx] = -1;
    buffer.nInactive++;
  }

  /// Activate a particle.
  int activateParticle(int type) {
    int i = buffer.firstInactiveParticleIdx;
    editParticle(i, type);
    buffer.nInactive--;
    return i;
  }

  /// Change a particle.
  ///
  /// This will effectively update the color and type of the selected particle.
  void editParticle(int i, int type) {
    // Set type.
    buffer.pType[i] = type;

    // Copy color.
    buffer.setParticleColor(i, info.particleInfo[type].rgba);
  }
}

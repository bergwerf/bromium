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

  /// Generate Domain list using the current membrane dimensions.
  List<Domain> generateMembraneDomains() {
    return new List<Domain>.generate(
        info.membranes.length,
        (int i) =>
            new Domain.fromType(info.membranes[i], buffer.getMembraneDims(i)));
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
  /// This will change particle [i] to [products.first], and activate a new
  /// particle for each other particle in [products].
  void unbindParticles(int i, List<int> products) {
    if (products.length == 0) {
      throw new Exception('cannot unbind into 0 products');
    }

    // Set the given particle to products.first.
    editParticle(i, products.first);

    // Activate the other products.
    var position = buffer.getParticleVec(i);
    for (var j = 1; j < products.length; j++) {
      int p = activateParticle(products[j]);
      buffer.setParticleCoords(p, position);
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
    if (buffer.nInactive == 0) {
      throw new Exception('activateParticle called but nInactive = 0');
    }

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

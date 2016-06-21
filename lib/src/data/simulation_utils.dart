// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Helper class that combines the simulation byte data and the simulation info.
class Sim {
  /// Static simulation information
  final SimulationInfo info;

  /// Simulation data buffer.
  final SimulationBuffer data;

  /// Temporary list of membrane domains.
  final List<Domain> membranes = new List<Domain>();

  /// Constuctor
  Sim(this.info, this.data) {
    for (var i = 0; i < info.membranes.length; i++) {
      // Note, the DomainType is 'casted' since passing enums to an isolate
      // somehow broke the enum values.
      membranes.add(new Domain.fromType(
          DomainType.values[info.membranes[i].index],
          data.getMembraneDimensions(i)));
    }
  }
}

/// Set particle coordinates.
void setParticleCoords(SimulationBuffer data, int p, Vector3 point) {
  for (var d = 0; d < 3; d++) {
    data.pCoords[p * 3 + d] = point[d].round();
  }
}

/// Set particle color.
void setParticleColor(SimulationBuffer data, int p, List<int> color) {
  for (var c = 0; c < 4; c++) {
    data.pColor[p * 4 + c] = color[c];
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
void bindParticles(Sim sim, int a, int b, int compositeType) {
  // Inactivate b.
  inactivateParticle(sim, b);

  // Set particle a to compositeType.
  editParticle(sim, a, compositeType);
}

/// Unbind particle
///
/// This will effectively activate the front of the inactive part of the
/// particle vextex buffer and change it into [typeB] while the given
/// particle is changed into [typeA]. An error is thrown if no inactive
/// particle exists.
void unbindParticles(Sim sim, int i, int typeA, int typeB) {
  // Set the given particle to typeA.
  editParticle(sim, i, typeA);

  // Set the first inactive particle.
  int particleB = activateParticle(sim, typeB);

  // Copy the location of the given particle to the typeB particle.
  for (var d = 0; d < 3; d++) {
    sim.data.pCoords[particleB * 3 + d] = sim.data.pCoords[i * 3 + d];
  }
}

/// Inactivate a particle.
void inactivateParticle(Sim sim, int i) {
  // Copy the last active particle into this particle.
  editParticle(sim, i, sim.data.pType[sim.data.lastActiveParticleIdx]);

  // Inactivate the last active particle.
  sim.data.pType[sim.data.lastActiveParticleIdx] = -1;
  sim.data.nInactive++;
}

/// Activate a particle.
int activateParticle(Sim sim, int type) {
  int i = sim.data.firstInactiveParticleIdx;
  editParticle(sim, i, type);
  sim.data.nInactive--;
  return i;
}

/// Change a particle.
///
/// This will effectively update the color and type of the selected particle.
void editParticle(Sim sim, int i, int type) {
  // Set type.
  sim.data.pType[i] = type;

  // Copy color.
  setParticleColor(sim.data, i, sim.info.particleInfo[type].rgba);
}

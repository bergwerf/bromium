// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Wrapper around Simulation with some tricks to quickly transfer it to an
/// isolate and back.
class SimulationZ {
  // All particle data that is not contained in the byte buffer.
  Int16List _hiddenParticleData;

  // The simulation object with the logger and the particle list removed.
  Simulation _strippedSimulation;

  SimulationZ(this._strippedSimulation) {
    _strippedSimulation.logger = null;

    // Compress particles.
    var list = new List<int>();
    for (var particle in _strippedSimulation.particles) {
      list.add(particle.type);
      list.addAll(particle.entered);
      list.add(-1);
    }
    _strippedSimulation.particles.clear();
    _hiddenParticleData = new Int16List.fromList(list);
  }

  // Unpack the simulation.
  Simulation unpack() {
    if (_strippedSimulation.particles.isNotEmpty) {
      return _strippedSimulation;
    } else {
      // Add new logger.
      _strippedSimulation.logger = new Logger('Simulation');

      final buffer = _strippedSimulation.buffer;
      var offset = _strippedSimulation.particlesOffset;

      for (var i = 0; i < _hiddenParticleData.length;) {
        // Read compressed particle data.
        var type = _hiddenParticleData[i++];
        var entered = new List<int>();
        var membrane = 0;
        while ((membrane = _hiddenParticleData[i++]) != -1) {
          entered.add(membrane);
        }

        // Create data views.
        final position = new Vector3.fromBuffer(buffer, offset);
        offset += position.storage.lengthInBytes;
        final color = new Vector3.fromBuffer(buffer, offset);
        offset += color.storage.lengthInBytes;
        final displayRadius = new Float32View(buffer, offset);
        offset += displayRadius.sizeInBytes;
        final stepRadius = new Float32View(buffer, offset);
        offset += displayRadius.sizeInBytes;

        // Add particle.
        _strippedSimulation.particles.add(new Particle.raw(
            type, position, color, displayRadius, stepRadius, entered));
      }

      return _strippedSimulation;
    }
  }
}

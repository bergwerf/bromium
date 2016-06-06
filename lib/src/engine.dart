// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class BromiumEngine {
  /// Simulation data
  BromiumData data;

  /// Constructor
  BromiumEngine();

  /// Clear all old particles and allocate new ones.
  void allocateParticles(ParticleDict particles, List<ParticleSet> sets,
      {bool useIntegers: true, int voxelsPerUnit: 100}) {
    // Compute total count.
    int count = 0;
    sets.forEach((ParticleSet s) {
      count += s.count;
    });

    // Allocate new data buffers.
    data = new BromiumData(useIntegers, voxelsPerUnit, count);

    // Create new random number generator.
    var rng = new Random();

    // Loop through all particle sets.
    for (var i = 0, p = 0; i < sets.length; i++) {
      // Get the particle info for this set.
      var info = particles.info[sets[i].label];

      // Assign coordinates and color to each particle.
      for (var j = 0; j < sets[i].count; j++, p++) {
        // Assign particle type.
        data.particleType[p] = info.index;

        // Assign a random position within the domain.
        var randPoint = sets[i].domain.computeRandomPoint(rng);
        for (var d = 0; d < 3; d++) {
          // XYZ
          if (data.useIntegers) {
            data.particleUint16Position[p * 3 + d] =
                (randPoint[d] * data.voxelsPerUnit).round();
          } else {
            data.particleFloatPosition[p * 3 + d] = randPoint[d];
          }
        }

        // Assign color.
        for (var c = 0; c < 4; c++) {
          // RGBA
          data.particleColor[p * 4 + c] = info.glcolor[c];
        }
      }
    }
  }

  /// Simulate one step of brownian motion.
  void applyBrownianMotion() {
    var rng = new Random();
    if (data.useIntegers) {
      for (var i = 0; i < data.particleUint16Position.length; i++) {
        // Give all values a random displacement.
        // Note that nextInt(11) generates an integer from 0 to 10.
        data.particleUint16Position[i] += rng.nextInt(11) - 5;
      }
    } else {
      // Use floating point.
      for (var i = 0; i < data.particleFloatPosition.length; i++) {
        // Give all values a random displacement.
        data.particleFloatPosition[i] += (rng.nextDouble() - .5) * 0.1;
      }
    }
  }

  /// Simulate one step in the particle simulation.
  void step() {
    applyBrownianMotion();
    mphfMapKinetics(data);
  }
}

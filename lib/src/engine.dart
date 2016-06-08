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
      List<BindReaction> bindReactions,
      {bool useIntegers: true, int voxelsPerUnit: 100}) {
    // Compute total count.
    int count = 0, inactiveCount = 0;
    sets.forEach((ParticleSet s) {
      count += s.count;
      inactiveCount += s.count * (particles.computeParticleSize(s.label) - 1);
    });

    // Generate internal bind reactions data.
    var internalBindReactions = new List<_BindReaction>(bindReactions.length);
    for (var i = 0; i < bindReactions.length; i++) {
      var r = bindReactions[i];
      internalBindReactions[i] = new _BindReaction(
          particles.info[r.particleA].index,
          particles.info[r.particleB].index,
          particles.info[r.particleC].index,
          r.distance,
          computeSphericalVoxelGroup(r.distance, voxelsPerUnit));
    }

    // Allocate new data buffers.
    data = new BromiumData.allocate(useIntegers, voxelsPerUnit,
        particles.indices.length, count + inactiveCount, internalBindReactions);

    // Copy particle color settings.
    particles.info.forEach((_, ParticleInfo info) {
      for (var c = 0; c < 4; c++) {
        // RGBA
        data.particleColorSettings[info.index * 4 + c] = info.glcolor[c];
      }
    });

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
            // TODO: performance tests with [voxelSpaceSize]
            data.particleUint16Position[p * 3 + d] =
                (randPoint[d] * data.voxelsPerUnit + voxelSpaceSizeHalf)
                    .round();
          } else {
            data.particleFloatPosition[p * 3 + d] =
                randPoint[d] + voxelSpaceSizeHalf / data.voxelsPerUnit;
          }
        }

        // Assign color.
        for (var c = 0; c < 4; c++) {
          // RGBA
          data.particleColor[p * 4 + c] = info.glcolor[c];
        }
      }
    }

    // Set all inactive particles to inactive.
    for (var i = 0; i < inactiveCount; i++) {
      data.particleType[count + i] = -1;
    }
  }

  /// Simulate one step of brownian motion.
  /// Note: add domain overflow protection.
  void applyBrownianMotion() {
    var rng = new Random();
    for (var i = 0; i < data.particleType.length; i++) {
      // If the particleType is -1 the particle is inactive.
      if (data.particleType[i] != -1) {
        if (data.useIntegers) {
          for (var c = 0; c < 3; c++) {
            // Give all values a random displacement.
            // Note that nextInt(11) generates an integer from 0 to 10.
            data.particleUint16Position[i * 3 + c] += rng.nextInt(11) - 5;
          }
        } else {
          // Use decimal displacement.
          for (var c = 0; c < 3; c++) {
            // Give all values a random displacement.
            data.particleFloatPosition[i * 3 + c] +=
                (rng.nextDouble() - .5) * 0.1;
          }
        }
      }
    }
  }

  /// Simulate one step in the particle simulation.
  void step() {
    applyBrownianMotion();

    // Potential optimization: do not run kinetics computations if no reactions
    // are given (for example in a diffusion only animation with no or static
    // membranes). Note that the voxel tree structure is also required for
    // dynamic membranes.
    mphfMapKinetics(data);
  }
}

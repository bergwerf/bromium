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
      List<BindReaction> bindReactions, List<Membrane> membranes,
      {bool useIntegers: true, int voxelsPerUnit: 100}) {
    // Sanity check bind reactions.
    // TODO

    // Compute total count.
    int count = 0, inactiveCount = 0;
    sets.forEach((ParticleSet s) {
      count += s.count;
      inactiveCount += s.count * (particles.computeParticleSize(s.type) - 1);
    });

    // Generate voxel groups.
    for (var i = 0; i < bindReactions.length; i++) {
      bindReactions[i].initVoxelGroup(voxelsPerUnit);
    }

    // Allocate new data buffers.
    data = new BromiumData.allocate(
        useIntegers,
        voxelsPerUnit,
        particles.indices.length,
        count + inactiveCount,
        bindReactions,
        membranes);

    // Copy particle color settings and particle motion speed.
    particles.info.forEach((_, ParticleInfo info) {
      // Compute motion radius.
      data.randomWalkStep[info.index] =
          new _RandomWalkStep(info.motionSpeed, data.voxelsPerUnit);

      for (var c = 0; c < 4; c++) {
        // RGBA
        data.particleColorSettings[info.index * 4 + c] = info.glcolor[c];
      }
    });

    // Create new random number generator.
    var rng = new Random();

    // Loop through all particle sets.
    for (var i = 0, p = 0; i < sets.length; i++) {
      // Assign coordinates and color to each particle.
      for (var j = 0; j < sets[i].count; j++, p++) {
        // Assign particle type.
        data.particleType[p] = sets[i].type;

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
        var glcolor = particles.info[particles.indices[sets[i].type]].glcolor;
        for (var c = 0; c < 4; c++) {
          // RGBA
          data.particleColor[p * 4 + c] = glcolor[c];
        }
      }
    }

    // Set all inactive particles to inactive.
    for (var i = 0; i < inactiveCount; i++) {
      data.particleType[count + i] = -1;
    }
  }

  /// Simulate one step in the particle simulation.
  void step() {
    _computeMotion(data);

    // Potential optimization: do not run kinetics computations if no reactions
    // are given (for example in a diffusion only animation with no or static
    // membranes). Note that the voxel tree structure is also required for
    // dynamic membranes.
    _computeKinetics(data);
  }
}

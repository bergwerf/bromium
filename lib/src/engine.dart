// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class BromiumEngine {
  /// Simulation data
  BromiumData data;

  /// Benchmarks
  BromiumBenchmark benchmark;

  /// Constructor
  BromiumEngine() {
    // Start benchmark helper.
    benchmark = new BromiumBenchmark();
  }

  /// Clear all old particles and allocate new ones.
  void loadSimulation(
      VoxelSpace space,
      ParticleDict particles,
      List<ParticleSet> sets,
      List<BindReaction> bindReactions,
      List<Membrane> membranes) {
    benchmark.start('load new simulation');

    // Sanity check bind reactions.
    bindReactions.forEach((BindReaction r) {
      if (!particles.isValidBindReaction(r)) {
        throw new ArgumentError('bindReactions contains an invalid reaction');
      }
    });

    // Compute total count.
    int count = 0, inactiveCount = 0;
    sets.forEach((ParticleSet s) {
      count += s.count;
      inactiveCount += s.count * (particles.computeParticleSize(s.type) - 1);
    });

    // Allocate new data buffers.
    data = new BromiumData.allocate(space, particles.indices.length,
        count + inactiveCount, bindReactions, membranes);

    // Copy particle color settings and particle motion speed.
    particles.data.forEach((ParticleInfo info) {
      // Compute motion radius.
      data.randomWalkStep[info.index] = new _RandomWalkStep(info.rndWalkStepR);

      for (var c = 0; c < 4; c++) {
        // RGBA
        data.particleTypeColor[info.index * 4 + c] = info.glcolor[c];
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
          data.particlePosition[p * 3 + d] = randPoint[d].round();
        }

        // Assign color.
        var glcolor = particles.data[sets[i].type].glcolor;
        for (var c = 0; c < 4; c++) {
          data.particleColor[p * 4 + c] = glcolor[c];
        }
      }
    }

    // Set inactive particles.
    for (var i = 0; i < inactiveCount; i++) {
      data.particleType[count + i] = -1;
    }

    benchmark.end('load new simulation');
  }

  /// Compute scene center and scale.
  Tuple2<Vector3, double> computeSceneDimensions() {
    var center = new Vector3.zero();
    var _min = data.particlePosition.first.toDouble();
    var _max = _min;

    for (var i = 0; i < data.particlePosition.length; i += 3) {
      center.add(new Vector3(
          data.particlePosition[i + 0].toDouble(),
          data.particlePosition[i + 1].toDouble(),
          data.particlePosition[i + 2].toDouble()));

      for (var d = 0; d < 3; d++) {
        _min = min(_min, data.particlePosition[i + d]);
        _max = max(_max, data.particlePosition[i + d]);
      }
    }
    center.scale(1 / data.particleType.length);

    return new Tuple2<Vector3, double>(center, _max - _min);
  }

  /// Simulate one step in the particle simulation.
  void step() {
    benchmark.start('simulation step');
    benchmark.start('particle motion');
    _computeMotion(data);
    benchmark.end('particle motion');
    benchmark.start('particle reactions');
    computeReactionsWithArraySort(data);
    benchmark.end('particle reactions');
    benchmark.end('simulation step');
  }
}

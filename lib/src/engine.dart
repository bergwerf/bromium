// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class BromiumEngine {
  // Particle buffer that is rendered
  Uint16List particleType;
  Uint16List particleBound;
  Float32List particlePosition;
  Float32List particleColor;

  /// Particle information
  Map<String, ParticleInfo> particles = new Map<String, ParticleInfo>();

  /// Particle info index
  List<String> particleLabels = new List<String>();

  /// Constructor
  BromiumEngine();

  /// Add new particle.
  void addParticle(String label, double radius, Color color,
      {List<String> compound: const []}) {
    if (!particles.containsKey(label)) {
      int i = particleLabels.length;
      particleLabels.add(label);
      particles[label] = new ParticleInfo(i, radius, color);
    }
  }

  /// Add a new composite particle.
  void addCompound(String a, String b, String c, double radius, double bind,
      double unbind, Color color) {}

  /// Clear all old particles and allocate new ones.
  void allocateParticles(List<ParticleSet> sets) {
    // Compute total count.
    int count = 0;
    sets.forEach((ParticleSet s) {
      count += s.count;
    });

    // Allocate new data buffers.
    particleType = new Uint16List(count);
    particlePosition = new Float32List(count * 3);
    particleColor = new Float32List(count * 4);

    // Create new random number generator.
    var rng = new Random();

    // Loop through all particle sets.
    for (int i = 0, p = 0; i < sets.length; i++) {
      // Get the particle info for this set.
      var info = particles[sets[i].label];

      // Assign coordinates and color to each particle.
      for (int j = 0; j < sets[i].count; j++, p++) {
        // Assign particle type.
        particleType[p] = info.index;

        // Assign a random position within the domain.
        sets[i]
            .domain
            .computeRandomPoint(rng)
            .copyIntoArray(particlePosition, p * 3);

        // Assign color.
        for (int c = 0; c < 4; c++) {
          // RGBA
          particleColor[p * 4 + c] = info.glcolor[c];
        }
      }
    }
  }

  /// Simulate one step in the particle simulation.
  void step() {
    var rng = new Random();
    for (var i = 0; i < particlePosition.length; i++) {
      // Give all particles a random displacement.
      particlePosition[i] += (rng.nextDouble() - .5) * 0.1;
    }

    // Voxel data structures
    var voxel = new List<List<double>>(particleType.length);
    var tree = new Map<int, Map<int, Map<int, Map<int, List<int>>>>>();

    // Populate tree.
    for (var i = 0, j = 0; i < particleType.length; i++, j += 3) {
      voxel[i] = [
        particlePosition[j + 0] / 0.01,
        particlePosition[j + 1] / 0.01,
        particlePosition[j + 2] / 0.01
      ];

      var voxelX = voxel[i][0].round();
      var voxelY = voxel[i][1].round();
      var voxelZ = voxel[i][2].round();

      tree.putIfAbsent(
          voxelX, () => new Map<int, Map<int, Map<int, List<int>>>>());
      tree[voxelX]
          .putIfAbsent(voxelY, () => new Map<int, Map<int, List<int>>>());
      tree[voxelX][voxelY].putIfAbsent(voxelZ, () => new Map<int, List<int>>());
      tree[voxelX][voxelY][voxelZ]
          .putIfAbsent(particleType[i], () => new List<int>());
      tree[voxelX][voxelY][voxelZ][particleType[i]].add(i);
    }

    int aIdx = particleLabels.indexOf('A');
    int bIdx = particleLabels.indexOf('B');

    for (var i = 0, j = 0; i < particleType.length; i++, j += 3) {
      if (particleType[i] == aIdx) {
        // Append all voxels.
        var nearParticles = new List<int>();
        var nearVx = [
          [voxel[i][0].floor(), voxel[i][1].floor(), voxel[i][2].floor()],
          [voxel[i][0].floor(), voxel[i][1].floor(), voxel[i][2].ceil()],
          [voxel[i][0].floor(), voxel[i][1].ceil(), voxel[i][2].floor()],
          [voxel[i][0].floor(), voxel[i][1].ceil(), voxel[i][2].ceil()],
          [voxel[i][0].ceil(), voxel[i][1].floor(), voxel[i][2].floor()],
          [voxel[i][0].ceil(), voxel[i][1].floor(), voxel[i][2].ceil()],
          [voxel[i][0].ceil(), voxel[i][1].ceil(), voxel[i][2].floor()],
          [voxel[i][0].ceil(), voxel[i][1].ceil(), voxel[i][2].ceil()]
        ];

        for (var v = 0; v < nearVx.length; v++) {
          if (tree.containsKey(nearVx[v][0]) &&
              tree[nearVx[v][0]].containsKey(nearVx[v][1]) &&
              tree[nearVx[v][0]][nearVx[v][1]].containsKey(nearVx[v][2]) &&
              tree[nearVx[v][0]][nearVx[v][1]][nearVx[v][2]]
                  .containsKey(bIdx)) {
            nearParticles
                .addAll(tree[nearVx[v][0]][nearVx[v][1]][nearVx[v][2]][bIdx]);
          }
        }

        // If there is a near particle, bind with it.
        if (nearParticles.length > 0) {
          particleColor[i * 4] = 0.0;
          particleColor[i * 4 + 1] = 1.0;
          particleColor[nearParticles.first * 4 + 2] = 0.0;
        }
      }
    }
  }
}

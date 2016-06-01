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

  /// Constructor
  BromiumEngine();

  /// Add new particle.
  void addParticle(String label, double radius, Color color,
      {List<String> compound: const []}) {
    if (!particles.containsKey(label)) {
      particles[label] = new ParticleInfo(radius, color);
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
  }
}

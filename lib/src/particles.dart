// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Information of one particle in [ParticleDict]
class ParticleInfo {
  /// String label associated to this particle.
  final String label;

  /// Particle index
  final int index;

  /// Random walk step radius
  final double rndWalkStepR;

  /// Sub particles by their index.
  final List<int> subParticles;

  /// Particle color
  List<int> glcolor = new List<int>(4);

  /// Constructor
  ParticleInfo(this.label, this.index, this.rndWalkStepR, this.subParticles,
      Color color) {
    var rgb = color.toRgbColor();
    glcolor[0] = rgb.r;
    glcolor[1] = rgb.g;
    glcolor[2] = rgb.b;
    glcolor[3] = 255; // Alpha
  }
}

/// Dictionary of particle types
class ParticleDict {
  /// Particle data
  List<ParticleInfo> data = new List<ParticleInfo>();

  /// Particles indices
  Map<String, int> indices = new Map<String, int>();

  /// Get particle index by their label.
  int particle(String label) {
    return indices[label];
  }

  /// Calculate how many unsplittable parts the given particle contains.
  int computeParticleSize(int type) {
    if (data.length > type) {
      if (data[type].subParticles.isNotEmpty) {
        int size = 0;
        for (var p in data[type].subParticles) {
          size += computeParticleSize(p);
        }
        return size;
      } else {
        return 1;
      }
    } else {
      return 0;
    }
  }

  /// Add new particle.
  bool addParticle(
      String label, double rndWalkStepR, List<String> subParticles, Color color,
      {List<String> compound: const []}) {
    // Check if all subParticles are already defined.
    bool subParticlesValid = true;
    for (var p in subParticles) {
      if (!indices.containsKey(p)) {
        subParticlesValid = false;
        break;
      }
    }

    // If all subParticles are valid, it is impossible to insert cycles.
    if (!indices.containsKey(label) && subParticlesValid) {
      indices[label] = data.length;
      data.add(new ParticleInfo(
          label,
          indices[label],
          rndWalkStepR,
          new List<int>.generate(
              subParticles.length, (int i) => indices[subParticles[i]]),
          color));
      return true;
    } else {
      return false;
    }
  }

  /// Check if the given bind reaction is valid.
  bool isValidBindReaction(BindReaction r) {
    // TODO: this behaviour could be more flexible in the future.
    var sp = data[r.particleC].subParticles;
    return sp.length == 2 &&
        sp.contains(r.particleA) &&
        sp.contains(r.particleB);
  }
}

/// Collection of particles of the same type in a domain.
/// Used in [BromiumEngine.allocateParticles].
class ParticleSet {
  /// Particle type
  int type;

  /// Number of particles in this set
  int count;

  /// Particles domain
  Domain domain;

  /// Constructor
  ParticleSet(this.type, this.count, this.domain);
}

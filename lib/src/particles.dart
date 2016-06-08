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

  /// Random walk step max size.
  final double motionSpeed;

  /// Sub particles by their index.
  final List<int> subParticles;

  /// Particle color
  List<int> glcolor = new List<int>(4);

  /// Constructor
  ParticleInfo(this.label, this.index, this.motionSpeed, this.subParticles,
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
  /// Particle information
  Map<String, ParticleInfo> info = new Map<String, ParticleInfo>();

  /// Particle label index
  List<String> indices = new List<String>();

  /// Get particle index by their label.
  int operator [](String label) {
    return indices.indexOf(label);
  }

  /// Calculate how many unsplittable parts the given particle contains.
  int computeParticleSize(int type) {
    var label = indices[type];
    if (info.containsKey(label)) {
      if (info[label].subParticles.isNotEmpty) {
        int size = 0;
        for (var p in info[label].subParticles) {
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
      String label, double motionSpeed, List<String> subParticles, Color color,
      {List<String> compound: const []}) {
    // Check if all subParticles are already defined.
    bool subParticlesValid = true;
    for (var p in subParticles) {
      if (!info.containsKey(p)) {
        subParticlesValid = false;
        break;
      }
    }

    // If all subParticles are valid, it is impossible to insert cycles.
    if (!info.containsKey(label) && subParticlesValid) {
      indices.add(label);
      info[label] = new ParticleInfo(
          label,
          indices.length - 1,
          motionSpeed,
          new List<int>.generate(
              subParticles.length, (int i) => indices.indexOf(subParticles[i])),
          color);
      return true;
    } else {
      return false;
    }
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

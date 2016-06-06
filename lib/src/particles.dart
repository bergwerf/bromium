// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Information of one particle in [ParticleDict]
class ParticleInfo {
  /// Particle index
  int index;

  /// Particle bounding box radius
  double radius;

  /// Particle color
  List<int> glcolor = new List<int>(4);

  /// Constructor
  ParticleInfo(this.index, this.radius, Color color) {
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

  /// Add new particle.
  void addParticle(String label, double radius, Color color,
      {List<String> compound: const []}) {
    if (!info.containsKey(label)) {
      int i = indices.length;
      indices.add(label);
      info[label] = new ParticleInfo(i, radius, color);
    }
  }
}

/// Collection of particles of the same type in a domain.
/// Used in [BromiumEngine.allocateParticles].
class ParticleSet {
  /// Label of the particles in this set
  String label;

  /// Number of particles in this set
  int count;

  /// Particles domain
  Domain domain;

  /// Constructor
  ParticleSet(this.label, this.count, this.domain);
}

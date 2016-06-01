// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class ParticleInfo {
  /// Particle bounding box radius
  double radius;

  /// Particle color
  List<double> glcolor = new List<double>(4);

  /// Constructor
  ParticleInfo(this.radius, Color color) {
    var rgb = color.toRgbColor();
    glcolor[0] = rgb.r / 255;
    glcolor[1] = rgb.g / 255;
    glcolor[2] = rgb.b / 255;
    glcolor[3] = 1.0; // Alpha
  }
}

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

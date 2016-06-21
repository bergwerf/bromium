// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

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

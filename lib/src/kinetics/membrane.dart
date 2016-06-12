// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Base class for membranes
class Membrane {
  /// Membrane domain volume
  Domain domain;

  /// Particles that can move into the membrane.
  List<int> inwardPermeability;

  /// Particles that can move out of the membrane.
  List<int> outwardPermeability;

  /// Constructor
  Membrane(this.domain, this.inwardPermeability, this.outwardPermeability);

  /// An optimized version of [blockParticleMotion] for integers.
  bool blockParticleMotion(
      int particleType, int ax, int ay, int az, int bx, int by, int bz) {
    // If particleType is included in inwardPermeability and
    // outwardPermeability, you can skip the surfaceIntersection.
    var ip = inwardPermeability.contains(particleType);
    var op = outwardPermeability.contains(particleType);
    if (ip && op) {
      return false;
    } else {
      switch (domain.surfaceIntersection(ax, ay, az, bx, by, bz)) {
        case DomainIntersect.inwardIntersect:
          return !ip;
        case DomainIntersect.outwardIntersect:
          return !op;
        default:
          return false;
      }
    }
  }
}

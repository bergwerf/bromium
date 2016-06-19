// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Base class for membranes
class Membrane {
  /// Membrane domain volume
  Domain domain;

  /// Probability of particles moving into the membrane
  Map<int, double> inwardPermeability;

  /// Probability of particles moving out of the membrane
  Map<int, double> outwardPermeability;

  /// Random number generator to simulate permeability.
  Random _rng = new Random();

  /// Constructor
  Membrane(this.domain, this.inwardPermeability, this.outwardPermeability);

  /// An optimized version of [blockParticleMotion] for integers.
  bool blockParticleMotion(
      int particleType, int ax, int ay, int az, int bx, int by, int bz) {
    // If particleType is included in inwardPermeability and
    // outwardPermeability, you can skip the surfaceIntersection.
    var ip = _rng.nextDouble() < inwardPermeability[particleType];
    var op = _rng.nextDouble() < outwardPermeability[particleType];
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

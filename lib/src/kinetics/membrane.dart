// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Check if the given motion should be blocked.
bool membraneBlockParticleMotion(Simulation sim, Random rng, int membrane, int type,
    int ax, int ay, int az, int bx, int by, int bz) {
  var ip = rng.nextDouble() < sim.buffer.getInwardPermeability(membrane, type);
  var op = rng.nextDouble() < sim.buffer.getOutwardPermeability(membrane, type);
  if (ip && op) {
    return false;
  } else {
    switch (
        sim.membranes[membrane].surfaceIntersection(ax, ay, az, bx, by, bz)) {
      case DomainIntersect.inwardIntersect:
        return !ip;
      case DomainIntersect.outwardIntersect:
        return !op;
      default:
        return false;
    }
  }
}

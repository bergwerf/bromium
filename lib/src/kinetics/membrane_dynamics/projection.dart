// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Apply membrane dynamics (movement and scaling) for membranes with an
/// ellipsoidal shape.
void ellipsoidMembraneDynamicsWithProjection(Simulation sim) {
  // Loop through all membranes.
  for (var m = 0; m < sim.info.membranes.length; m++) {
    // Check if the membrane is ellipsoidal and if the dimensions have changed.
    if (sim.info.membranes[m] == DomainType.ellipsoid &&
        sim.buffer.membraneDimsChanged(m)) {
      sim.buffer.applyMembraneMotion(m);
    }
  }
}

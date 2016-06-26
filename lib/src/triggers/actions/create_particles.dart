// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Create particles of the specified [type] in the specified [membrane].
class CreateParticlesAction extends TriggerAction {
  final int particleType;

  final int particleCount;

  final Domain domain;

  CreateParticlesAction(this.particleType, this.particleCount, this.domain);

  void run(Simulation sim) {
    // Create temporary array of membrane domains.
    var membranes = sim.generateMembraneDomains();

    var rng = new Random();
    for (var i = 0; i < particleCount; i++) {
      int p = sim.activateParticle(particleType);
      var point = domain.computeRandomPoint(rng);
      sim.buffer.setParticleCoords(p, point);

      for (var m = 0; m < membranes.length; m++) {
        if (membranes[m].containsVec(point)) {
          sim.buffer.setParentMembrane(p, m);
        }
      }
    }
  }
}

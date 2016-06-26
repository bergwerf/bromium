// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Create particles of the specified [type] in the specified [membrane].
class CreateParticlesAction extends TriggerAction {
  final int particleType;

  final int particleCount;

  final int parentMembrane;

  CreateParticlesAction(
      this.particleType, this.particleCount, this.parentMembrane);

  void run(Simulation sim) {
    // Create temporary array of membrane domains.
    var membranes = sim.generateMembraneDomains();

    var rng = new Random();
    var parentDomain = new Domain.fromType(sim.info.membranes[parentMembrane],
        sim.buffer.getMembraneDims(parentMembrane));
    for (var i = 0; i < particleCount; i++) {
      int p = sim.activateParticle(particleType);
      var point = parentDomain.computeRandomPoint(rng);
      sim.buffer.setParticleCoords(p, point);

      for (var m = 0; m < membranes.length; m++) {
        if (membranes[m].containsVec(point)) {
          sim.buffer.setParentMembrane(p, m);
        }
      }
    }
  }
}

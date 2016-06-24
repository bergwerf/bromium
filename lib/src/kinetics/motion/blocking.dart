// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// This function applies one cycle of random motion to the given [BromiumData].
void computeMotion(Simulation sim) {
  // Create temporary array of membrane domains.
  var membranes = new List<Domain>.generate(
      sim.info.membranes.length,
      (int i) => new Domain.fromType(
          sim.info.membranes[i], sim.buffer.getOldMembraneDims(i)));

  // Apply random motion to all particles.
  var rng = new Random();
  OUTER: for (var i = 0; i < sim.buffer.nParticles; i++) {
    // If the particleType is -1 the particle is inactive.
    var type = sim.buffer.pType[i];
    if (type != -1) {
      // Compute random displacement.
      var odd = sim.info.particleInfo[type].rndWalkOdd;
      var sub = sim.info.particleInfo[type].rndWalkSub;
      var mx = rng.nextInt(odd) - sub;
      var my = rng.nextInt(odd) - sub;
      var mz = rng.nextInt(odd) - sub;

      // Check motion block due to membrane permeability.
      for (var m = 0; m < sim.info.membranes.length; m++) {
        var ip = rng.nextDouble() < sim.buffer.getInwardPermeability(m, type);
        var op = rng.nextDouble() < sim.buffer.getOutwardPermeability(m, type);
        if (!(ip && op)) {
          var x = sim.buffer.pCoords[i * 3 + 0];
          var y = sim.buffer.pCoords[i * 3 + 1];
          var z = sim.buffer.pCoords[i * 3 + 2];
          var containsBefore = sim.buffer.isInMembrane(i, m);
          var containsAfter = membranes[m].contains(x + mx, y + my, z + mz);
          var inward = !containsBefore && containsAfter;
          var outward = containsBefore && !containsAfter;

          if ((!ip && inward) || (!op && outward)) {
            continue OUTER;
          } else if (inward) {
            sim.buffer.setParentMembrane(i, m);
          } else if (outward) {
            sim.buffer.unsetParentMembrane(i, m);
          }
        }
      }

      // Apply motion.
      sim.buffer.pCoords[i * 3 + 0] += mx;
      sim.buffer.pCoords[i * 3 + 1] += my;
      sim.buffer.pCoords[i * 3 + 2] += mz;
    }
  }
}

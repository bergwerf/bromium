// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class GrowEllipsoid extends TriggerAction {
  final int membrane;

  final int particleType;

  final int maxParticleCount;

  final double startA, startB, startC, finalA, finalB, finalC;

  GrowEllipsoid(
      this.membrane,
      this.particleType,
      this.maxParticleCount,
      this.startA,
      this.startB,
      this.startC,
      this.finalA,
      this.finalB,
      this.finalC);

  void run(Simulation sim) {
    var n = sim.buffer.particleCountIn(particleType, membrane);
    n = min(n, maxParticleCount);
    var frac = n / maxParticleCount;
    var dims = sim.buffer.getMembraneDims(membrane);
    dims[3] = startA + frac * (finalA - startA);
    dims[4] = startB + frac * (finalB - startB);
    dims[5] = startC + frac * (finalC - startC);
    sim.buffer.setMembraneDims(membrane, dims);
  }
}

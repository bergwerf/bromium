// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Apply particle motion
void kineticsRandomMotion(Simulation sim) {
  var rng = new Random();
  OUTER: for (var particle in sim.particles) {
    var random = randomVector3(rng)..sub(new Vector3.all(.5));
    random.scale(sim.particleTypes[particle.type].stepRadius);
    var motion = particle.envMembrane >= 0
        ? sim.membranes[particle.envMembrane].speed + random
        : random;

    // Check motion block due to allowed flux fraction.
    var m = 0;
    for (var membrane in sim.membranes) {
      var ip = rng.nextDouble() < membrane.ffIn[particle.type];
      var op = rng.nextDouble() < membrane.ffOut[particle.type];
      if (!(ip && op)) {
        var before = membrane.domain.contains(particle.position);
        var after = membrane.domain.contains(particle.position + motion);
        var inward = !before && after;
        var outward = before && !after;

        if ((!ip && inward) || (!op && outward)) {
          continue OUTER;
        } else if (inward) {
          particle.envMembrane = m;
          particle.entered.add(m);
        } else if (outward) {
          particle.entered.remove(m);
          particle.envMembrane = particle.entered.last;
        }
      }

      // Move to the next membrane.
      m++;
    }

    // Apply motion.
    particle.position.add(random);
  }
}

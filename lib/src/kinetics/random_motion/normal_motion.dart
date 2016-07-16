// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Normal particle random motion algorithm.
void particlesRandomMotionNormal(Simulation sim) {
  var rng = new Random();
  OUTER: for (var particle in sim.particles) {
    // Note: normalize and randomly scale for a constant max radius.
    var random = randomVector3(rng)
      ..sub(new Vector3.all(.5))
      ..normalize()
      ..scale(rng.nextDouble() * particle.stepRadius.get());
    var motion = particle.entered.isNotEmpty
        ? sim.membranes[particle.entered.last].speed + random
        : random;

    // Check motion block due to allowed flux fraction.
    // TODO: delay computation by computing movement distance until hit.
    var m = 0;
    for (var membrane in sim.membranes) {
      var ip = rng.nextDouble() < membrane.passIn[particle.type];
      var op = rng.nextDouble() < membrane.passOut[particle.type];
      if (!(ip && op)) {
        var before = particle.entered.contains(m);
        var after = membrane.domain.contains(particle.position + motion);
        var inward = !before && after;
        var outward = before && !after;

        if ((!ip && inward) || (!op && outward)) {
          continue OUTER;
        } else if (inward) {
          particle.entered.add(m);
        } else if (outward) {
          particle.entered.remove(m);
        }
      }

      // Move to the next membrane.
      m++;
    }

    // Apply motion.
    particle.position.add(random);
  }
}

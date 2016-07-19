// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Normal particle random motion algorithm.
void particlesRandomMotionNormal(Simulation sim) {
  var rng = new Random();
  OUTER: for (var particle in sim.particles) {
    if (particle.isSticked) {
      // Sticked particles are displaced by computing a surface normal and
      // projecting the displacement.
      // TODO: implement sticked particle motion.
    } else {
      // Normal random motion is computed by scaling a normalized random vector
      // by a random value and the motion radius.
      var random = randomVector3(rng)
        ..sub(new Vector3.all(.5))
        ..normalize()
        ..scale(rng.nextDouble() * particle.speed);
      var motion = particle.entered.isNotEmpty
          ? sim.membranes[particle.entered.last].speed + random
          : random;

      // Check motion block due to allowed flux fraction.
      // TODO: delay computation by computing movement distance until hit.
      var m = 0;
      final type = particle.type;
      for (var membrane in sim.membranes) {
        final before = particle.hasEntered(m);
        final after = membrane.domain.contains(particle.position + motion);
        final enters = !before && after;
        final leaves = before && !after;

        // If the particle sticks: stick it and continue to the next particle.
        if (membrane.stick(type, enters, leaves)) {
          // Stick the particle.
          particle.stickTo(m, membrane.domain);
          membrane.stickedCount[type]++;
        }

        // Note: boolean conditions are resolved sequentially, this allows some
        // optimizations in this code (e.g. check enters/leaves first).
        if ((enters && !membrane.mayEnter(type)) ||
            (leaves && !membrane.mayLeave(type))) {
          continue OUTER;
        } else if (enters) {
          particle.pushEntered(m);
          membrane.insideCount[type]++;
        } else if (leaves) {
          particle.popEntered(m);
          membrane.insideCount[type]--;
        }

        // Move to the next membrane.
        m++;
      }

      // Apply motion.
      particle.position.add(random);
    }
  }
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Normal particle random motion algorithm.
void particlesRandomMotionNormal(Simulation sim) {
  var rng = new Random();
  OUTER: for (var particle in sim.particles) {
    if (particle.sticked != -1) {
      // Sticked particles are displaced by computing a surface normal and
      // projecting the displacement.
    } else {
      // Normal random motion is computed by scaling a normalized random vector
      // by a random value and the motion radius.
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
        final mayEnter = membrane.mayEnter(particle.type);
        final mayLeave = membrane.mayLeave(particle.type);
        if (!(mayEnter && mayLeave)) {
          final before = particle.hasEntered(m);
          final after = membrane.domain.contains(particle.position + motion);
          final entered = !before && after;
          final left = before && !after;

          if ((!mayEnter && entered) || (!mayLeave && left)) {
            continue OUTER;
          } else if (entered) {
            particle.pushEntered(m);
          } else if (left) {
            particle.popEntered(m);
          }
        }

        // Move to the next membrane.
        m++;
      }

      // Apply motion.
      particle.position.add(random);
    }
  }
}

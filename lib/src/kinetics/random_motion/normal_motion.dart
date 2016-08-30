// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Normal particle random motion algorithm.
void particlesRandomMotionNormal(Simulation sim) {
  var rng = new Random();

  // We reuse this variable as much as possible to save allocation time.
  final motion = new Vector3.zero();

  OUTER: for (final particle in sim.particles) {
    if (particle.isSticked) {
      // Sticked particles are displaced by computing a surface normal and
      // projecting the displacement.
      // TODO: implement sticked particle motion.
    } else {
      // Normal random motion is computed by scaling a normalized random vector
      // by a random value and the motion radius.
      randomSphericalVector3(rng, motion);
      motion.scale(particle.speed);
      motion.add(particle.position);

      // Check motion block due to allowed flux fraction.
      final type = particle.type;
      for (var m = 0; m < sim.membranes.length; m++) {
        // Check if the particle can already possibly hit the membrane.
        if (particle.minSteps[m] == 0) {
          final membrane = sim.membranes[m];

          // Update minSteps.
          particle.minSteps[m] =
              (membrane.domain.minSurfaceToPoint(motion) / particle.speed)
                  .floor();

          // Check if the particle has crossed the membrane.
          final before = particle.hasEntered(m);
          final after = membrane.domain.contains(motion);
          final enters = !before && after;
          final leaves = before && !after;

          // If the particle sticks: stick it and continue to the next particle.
          if (membrane.stick(type, enters, leaves)) {
            membrane.leaveParticleUnsafe(particle);
            membrane.stickParticleUnsafe(particle);
            continue OUTER;
          }

          // Note: boolean conditions are resolved sequentially, this allows
          // some optimizations in this code (e.g. check enters/leaves first).
          if ((enters && !membrane.mayEnter(type)) ||
              (leaves && !membrane.mayLeave(type))) {
            continue OUTER;
          } else if (enters) {
            membrane.enterParticleUnsafe(particle);
          } else if (leaves) {
            membrane.leaveParticleUnsafe(particle);
          }
        } else {
          // Go one step closer.
          particle.minSteps[m]--;
        }
      }

      // Apply motion.
      particle.position.setFrom(motion);
    }
  }
}

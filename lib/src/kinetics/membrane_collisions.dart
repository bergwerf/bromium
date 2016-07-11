// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Fix membrane motion induced particle collisions.
void fixMembraneCollisions(Simulation sim, Map<int, Domain> updatedMembranes) {
  // Projection offset (particles are not projected exactly on the domain
  // surface).
  var poff = 0.01;

  var rng = new Random();

  // Loop through all updated membranes.
  updatedMembranes.forEach((int m, Domain newDomain) {
    final membrane = sim.membranes[m];
    final oldDomain = membrane.domain;

    // Iterate through all particles.
    for (var i = 0; i < sim.particles.length; i++) {
      final particle = sim.particles[i];

      var ip = rng.nextDouble() < membrane.ffIn[particle.type];
      var op = rng.nextDouble() < membrane.ffOut[particle.type];

      if (oldDomain.contains(particle.position)) {
        if (!newDomain.contains(particle.position)) {
          if (op) {
            // Inner particle has legally moved outward.
            particle.entered.remove(m);
          } else {
            // Inner particle has illegally moved outward: project back inside.
            var proj = _innerProj(particle.position, newDomain, poff);
            particle.setPosition(proj);
          }
        }
      } else if (newDomain.contains(particle.position)) {
        if (ip) {
          // Outer particle has legally moved inward.
          particle.entered.add(m);
        } else {
          // Outer particle has illegally moved inward: project back outside.
          var proj = _outerProj(particle.position, oldDomain, newDomain, poff);
          particle.setPosition(proj);
        }
      }
    }
  });
}

/// Project the given [particle] on the inside of the [membrane] surface.
Vector3 _innerProj(Vector3 particle, Domain membrane, double offset) {
  // Translate particle to relative domain at (0, 0, 0).
  particle -= membrane.center;

  // Construct ray from the particle towards the domain center at (0, 0, 0).
  // Note that we use a unit direction vector so we can apply the offset later.
  var ray =
      new Ray.originDirection(particle, (particle * -1.0) / particle.length);

  // Compute projection.
  var proj = membrane.computeRayIntersections(ray);

  // Compute the smallest t (nearest to the particle).
  // Note that t should be positive since the particle should be outside the
  // ellipsoid.
  var t = proj.reduce(min);

  // Return projected point with extra offset towards the membrane center.
  return ray.at(t + offset) + membrane.center;
}

/// Project the given [particle] on the outside of the [newMembrane] surface.
Vector3 _outerProj(
    Vector3 particle, Domain oldMembrane, Domain newMembrane, double offset) {
  // Translate particle to relative membrane at (0, 0, 0).
  particle -= newMembrane.center;

  // Construct ray from the old membrane center towards the particle.
  var relativeOldMembrane = oldMembrane.center - newMembrane.center;
  var direction = particle - relativeOldMembrane;
  var ray = new Ray.originDirection(relativeOldMembrane, direction);

  // Compute projection.
  var proj = newMembrane.computeRayIntersections(ray);
  if (proj.isEmpty) {
    return particle + newMembrane.center;
  }

  // Compute the largest positive t (particle collide with the first ellipsoid
  // surface that is moving towards them, the ray points in this direction so
  // the largest positive t is the first surface the particles collide with).
  var t = proj.reduce(max);

  // Return projected point with extra offset away from the new membrane
  // center.
  var point = ray.at(t);
  var offsetVec = point / point.length;
  return point + newMembrane.center + offsetVec.scaled(offset);
}

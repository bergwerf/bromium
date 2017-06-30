// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

/// Fix membrane motion induced particle collisions.
void fixMembraneCollisions(Simulation sim, Map<int, Domain> updatedMembranes) {
  // Note that it is no problem to project particles exactly on the surface of a
  // membrane since Particle.entered will be used in the next cycle to determine
  // if the old particle position is contained in the membrane and not the old
  // position and the updated membrane dimensions.

  // Loop through all updated membranes.
  updatedMembranes.forEach((m, newDomain) {
    final membrane = sim.membranes[m];
    final oldDomain = membrane.domain;

    // Iterate through all particles.
    for (var i = 0; i < sim.particles.length; i++) {
      final particle = sim.particles[i];

      if (particle.hasEntered(m)) {
        if (!newDomain.contains(particle.position)) {
          if (membrane.mayLeave(particle.type)) {
            // Inner particle has legally moved outward.
            particle.entered.remove(m);
          } else {
            // Inner particle has illegally moved outward: project back inside.
            final proj = _innerProj(particle.position, newDomain);
            particle.position = proj;
          }
        }
      } else if (newDomain.contains(particle.position)) {
        if (membrane.mayEnter(particle.type)) {
          // Outer particle has legally moved inward.
          particle.entered.add(m);
        } else {
          // Outer particle has illegally moved inward: project back outside.
          final proj = _outerProj(particle.position, oldDomain, newDomain);
          particle.position = proj;
        }
      }
    }
  });
}

/// Project the given [particle] on the inside of the [membrane] surface.
Vector3 _innerProj(Vector3 particle, Domain membrane) {
  // Translate particle to relative domain at (0, 0, 0).
  final relP = particle - membrane.center;

  // Construct ray from the particle towards the domain center at (0, 0, 0).
  // Note that we use a unit direction vector so we can apply the offset later.
  final ray = new Ray.originDirection(relP, (relP * -1.0) / relP.length);

  // Compute projection.
  final proj = membrane.computeRayIntersections(ray);

  // Compute the smallest t (nearest to the particle).
  // Note that t should be positive since the particle should be outside the
  // ellipsoid.
  final t = proj.reduce(min);

  // Return projected point.
  return ray.at(t) + membrane.center;
}

/// Project the given [particle] on the outside of the [newMembrane] surface.
Vector3 _outerProj(Vector3 particle, Domain oldMembrane, Domain newMembrane) {
  // Translate particle to relative membrane at (0, 0, 0).
  final relP = particle - newMembrane.center;

  // Construct ray from the old membrane center towards the particle.
  final relativeOldMembrane = oldMembrane.center - newMembrane.center;
  final direction = relP - relativeOldMembrane;
  final ray = new Ray.originDirection(relativeOldMembrane, direction);

  // Compute projection.
  final proj = newMembrane.computeRayIntersections(ray);
  if (proj.isEmpty) {
    return relP + newMembrane.center;
  }

  // Compute the largest positive t (particle collide with the first ellipsoid
  // surface that is moving towards them, the ray points in this direction so
  // the largest positive t is the first surface the particles collide with).
  final t = proj.reduce(max);

  // Return projected point.
  return ray.at(t) + newMembrane.center;
}

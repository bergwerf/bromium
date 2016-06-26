// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Apply membrane dynamics (movement and scaling) for membranes with an
/// ellipsoidal shape.
void ellipsoidMembraneDynamicsWithProjection(Simulation sim) {
  // Projection offset (particles are not projected exactly on the domain
  // surface).
  var poff = 1.0;

  // Loop through all membranes.
  for (var m = 0; m < sim.info.membranes.length; m++) {
    // Check if the membrane is ellipsoidal and if the dimensions have changed.
    if (sim.info.membranes[m] == DomainType.ellipsoid &&
        sim.buffer.membraneDimsChanged(m)) {
      var oldDomain =
          new EllipsoidDomain.fromDims(sim.buffer.getMembraneDims(m));
      var newDomain =
          new EllipsoidDomain.fromDims(sim.buffer.getMembraneDims(m, true));

      // Iterate through all particles.
      for (var i = 0; i < sim.buffer.nParticles; i++) {
        // Skip -1 particles.
        if (sim.buffer.pType[i] == -1) {
          continue;
        }

        var ip = sim.buffer.rndInwardPermeability(i, m);
        var op = sim.buffer.rndOutwardPermeability(i, m);
        var particle = sim.buffer.getParticleVec(i);

        if (sim.buffer.isInMembrane(i, m)) {
          if (!newDomain.containsVec(particle)) {
            if (op) {
              sim.buffer.unsetParentMembrane(i, m);
            } else {
              // Inner particle that is now illegally outside: apply projection.
              var projPos = _innerProjection(particle, newDomain, poff);
              sim.buffer.setParticleCoords(i, projPos);
            }
          }
        } else if (newDomain.containsVec(particle)) {
          if (ip) {
            sim.buffer.setParentMembrane(i, m);
          } else {
            // Outer particle that is now illegally inside: apply projection.
            var projPos =
                _outerProjection(particle, oldDomain, newDomain, poff);
            sim.buffer.setParticleCoords(i, projPos);
          }
        }
      }

      // Finally apply the new dimensions.
      sim.buffer.applyMembraneMotion(m);
    }
  }
}

/// Project the given [particle] on the inside of the [ellipsoid] surface.
Vector3 _innerProjection(
    Vector3 particle, EllipsoidDomain ellipsoid, double offset) {
  // Translate particle to relative ellopsoid at (0, 0, 0).
  particle -= ellipsoid.center;

  // Construct ray from the particle towards the ellipsoid center at (0, 0, 0).
  // Note that we use a unit direction vector so we can apply an offset later.
  var ray =
      new Ray.originDirection(particle, (particle * -1.0) / particle.length);

  // Compute the smallest t (nearest to the particle).
  // Note that t should be positive since the particle should be outside the
  // ellipsoid.
  var proj = _ellipsoidProjection(ray, ellipsoid);
  var t = min(proj.item1, proj.item2);

  // Return projected point with extra offset towards the ellipsoid center.
  return ray.at(t + offset) + ellipsoid.center;
}

/// Project the given [particle] on the outside of the [newEllipsoid] surface.
Vector3 _outerProjection(Vector3 particle, EllipsoidDomain oldEllipsoid,
    EllipsoidDomain newEllipsoid, double offset) {
  // Translate particle to relative ellopsoid at (0, 0, 0).
  particle -= newEllipsoid.center;

  // Construct ray from the old ellipsoid center towards the particle.
  var relOldEllipsoid = oldEllipsoid.center - newEllipsoid.center;
  var direction = particle - relOldEllipsoid;
  var ray = new Ray.originDirection(relOldEllipsoid, direction);

  // Compute the largest positive t (particle collide with the first ellipsoid
  // surface that is moving towards them, the ray points in this direction so
  // the largest positive t is the first surface the particle collide with).
  var proj = _ellipsoidProjection(ray, newEllipsoid);
  if (proj == null) {
    return particle + newEllipsoid.center;
  }
  var t = max(proj.item1, proj.item2);

  // Return projected point with extra offset away from the new ellipsoid
  // center.
  var point = ray.at(t);
  var offsetVec = point / point.length;
  return point + newEllipsoid.center + offsetVec.scaled(offset);
}

Tuple2<double, double> _ellipsoidProjection(Ray ray, EllipsoidDomain e) {
  /// # Ellipsoid equation
  /// `x^2/a^2 + y^2/b^2 + z^2/c^2 = 1`
  ///
  /// # Ray equation
  /// `ray.origin + t * ray.direction`
  ///
  /// # Intersection
  ///
  /// ## Substitute ray equation in ellipsoid equation
  /// `(rox + t*rdx)^2/a^2 + (roy + t*rdy)^2/b^2 + (roz + t*rdz)^2/c^2 = 1`
  ///
  /// ## Simplify to simple 2nd degree polynomial form
  /// `A * t^2 + B * t + C = 0`
  ///
  /// Where:
  /// - `A = b^2 c^2 xD^2 + a^2 c^2 yD^2 + a^2 b^2 zD^2`
  /// - `B = b^2 c^2 2 xO xD + a^2 c^2 2 yO yD + a^2 b^2 2 zO zD`
  /// - `C = b^2 c^2 xO^2 + a^2 c^2 yO^2 + a^2 b^2 zO^2 - a^2 b^2 c^2`

  var asq = e.a * e.a, bsq = e.b * e.b, csq = e.c * e.c;
  var ab = asq * bsq, ac = asq * csq, bc = bsq * csq;

  var xO = ray.origin.x, yO = ray.origin.y, zO = ray.origin.z;
  var xD = ray.direction.x, yD = ray.direction.y, zD = ray.direction.z;

  var A = bc * xD * xD + ac * yD * yD + ab * zD * zD;
  var B = bc * 2 * xO * xD + ac * 2 * yO * yD + ab * 2 * zO * zD;
  var C = bc * xO * xO + ac * yO * yO + ab * zO * zO - asq * bsq * csq;
  var D = B * B - 4 * A * C;

  if (D < 0) {
    return null;
  } else {
    var dRoot = sqrt(D);
    return new Tuple2<double, double>(
        (-B + dRoot) / (2 * A), (-B - dRoot) / (2 * A));
  }
}

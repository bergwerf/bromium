// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Compute ray/ellipsoid intersection.
List<double> computeRayEllipsoidIntersection(Ray ray, EllipsoidDomain e) {
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

  final asq = e.semiAxes.x * e.semiAxes.x;
  final bsq = e.semiAxes.y * e.semiAxes.y;
  final csq = e.semiAxes.z * e.semiAxes.z;
  final ab = asq * bsq, ac = asq * csq, bc = bsq * csq;

  // Translate ray origin so that the ellipsoid center is at (0, 0, 0).
  final zeroOrigin = ray.origin - e.center;
  final xO = zeroOrigin.x, yO = zeroOrigin.y, zO = zeroOrigin.z;
  final xD = ray.direction.x, yD = ray.direction.y, zD = ray.direction.z;

  final A = bc * xD * xD + ac * yD * yD + ab * zD * zD;
  final B = bc * 2 * xO * xD + ac * 2 * yO * yD + ab * 2 * zO * zD;
  final C = bc * xO * xO + ac * yO * yO + ab * zO * zO - asq * bsq * csq;
  final D = B * B - 4 * A * C;

  if (D < 0) {
    return null;
  } else {
    var dRoot = sqrt(D);
    return [(-B + dRoot) / (2 * A), (-B - dRoot) / (2 * A)];
  }
}

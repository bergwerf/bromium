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

  var asq = e.semiAxes.x * e.semiAxes.x;
  var bsq = e.semiAxes.y * e.semiAxes.y;
  var csq = e.semiAxes.z * e.semiAxes.z;
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
    return [(-B + dRoot) / (2 * A), (-B - dRoot) / (2 * A)];
  }
}

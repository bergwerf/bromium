// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Compute ray/AABB intersection.
List<double> computeRayAabbIntersections(Ray ray, Aabb3 aabb) {
  var intersections = new List<double>();
  var dims = [
    aabb.min.x,
    aabb.max.x,
    aabb.min.y,
    aabb.max.y,
    aabb.min.z,
    aabb.max.z
  ];
  var rarray = [
    ray.origin.x,
    ray.direction.x,
    ray.origin.y,
    ray.direction.y,
    ray.origin.z,
    ray.direction.z
  ];

  for (var d = 0; d < 3; d++) {
    // Skip if the direction value is 0.
    if (rarray[d * 2 + 1] == 0) {
      continue;
    }

    for (var f = 0; f < 2; f++) {
      // Compute intersection point.
      var t = (dims[d * 2 + f] - rarray[d * 2]) / rarray[d * 2 + 1];

      // Compute index of other dimensions.
      var a = (d + 1) % 3;
      var b = (d + 2) % 3;

      // Compute other dimensions.
      var av = rarray[a * 2] + t * rarray[a * 2 + 1];
      var bv = rarray[b * 2] + t * rarray[b * 2 + 1];

      // Check if the intersection lies within a face.
      if (av > dims[a * 2] &&
          av < dims[a * 2 + 1] &&
          bv > dims[b * 2] &&
          bv < dims[b * 2 + 1]) {
        intersections.add(t);

        if (intersections.length == 2) {
          // There can only be two intersections.
          return intersections;
        }
      }
    }
  }

  return intersections;
}

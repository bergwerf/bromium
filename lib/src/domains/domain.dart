// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Intersection type for [Domain.surfaceIntersection].
enum DomainIntersect { noIntersect, inwardIntersect, outwardIntersect }

/// A particle domain for the BromiumEngine
abstract class Domain {
  /// Compute a random point within the domain.
  Vector3 computeRandomPoint(Random rng);

  /// Generate a GL_LINES wireframe outlining this domain.
  Float32List computeWireframe();

  /// Generate a GL_TRIANGLES polygon outlining this domain.
  Float32List computePolygon();

  /// Check if the given voxel is contained in this domain.
  bool containsVoxel(int x, int y, int z);

  /// Check if the given step (from voxel A to voxel B) intersects with the
  /// domain surface
  ///
  /// The default implementation relies on [containsVoxel] and checks if the
  /// origin is inside the membrane before and after the motion is applied.
  DomainIntersect surfaceIntersection(
      int ax, int ay, int az, int bx, int by, int bz) {
    var before = containsVoxel(ax, ay, az);
    var after = containsVoxel(bx, by, bz);
    return !before && after
        ? DomainIntersect.inwardIntersect
        : (before && !after
            ? DomainIntersect.outwardIntersect
            : DomainIntersect.noIntersect);
  }
}

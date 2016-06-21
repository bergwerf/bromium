// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Intersection type for [Domain.surfaceIntersection].
enum DomainIntersect { noIntersect, inwardIntersect, outwardIntersect }

/// Available [Domain] types
enum DomainType { cuboid, ellipsoid }

/// A particle domain for the BromiumEngine
abstract class Domain {
  final DomainType type;

  /// Default contsuctor
  Domain(this.type);

  /// Create [Domain] from a [DomainType] and an array of dimensions.
  factory Domain.fromType(DomainType type, Float32List dims) {
    switch (type) {
      case DomainType.cuboid:
        return new CuboidDomain.fromDims(dims);
      case DomainType.ellipsoid:
        return new EllipsoidDomain.fromDims(dims);
      default:
        return null;
    }
  }

  /// Get dimensions as floating point array.
  Float32List getDims();

  /// Get bounding box.
  CuboidDomain computeBoundingBox();

  /// Compute a random point within the domain.
  Vector3 computeRandomPoint(Random rng) {
    // The default implementation uses containsPoint and computeBoundingBox.
    Vector3 point;
    var bbox = computeBoundingBox();
    do {
      point.x = bbox.sc.x + rng.nextDouble() * (bbox.lc.x - bbox.sc.x);
      point.y = bbox.sc.y + rng.nextDouble() * (bbox.lc.y - bbox.sc.y);
      point.z = bbox.sc.z + rng.nextDouble() * (bbox.lc.z - bbox.sc.z);
    } while (!containsVec(point));
    return point;
  }

  /// Check if the given point is contained in this domain.
  bool containsVec(Vector3 point) {
    return contains(point.x, point.y, point.z);
  }

  /// Check if the given voxel is contained in this domain.
  bool containsVoxel(int x, int y, int z) {
    return contains(x, y, z);
  }

  /// Check if the given coordinates are contained in this domain.
  /// Points that touch the domain surface are also contained.
  bool contains(num x, num y, num z);

  /// Generate a GL_LINES wireframe outlining this domain.
  Float32List computeWireframe();

  /// Generate a GL_TRIANGLES polygon outlining this domain.
  Float32List computePolygon();

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

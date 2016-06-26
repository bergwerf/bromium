// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Available [Domain] types
enum DomainType { box, ellipsoid }

/// A particle domain for the BromiumEngine
abstract class Domain {
  /// The domain type
  final DomainType type;

  /// Cavities in the domain
  final List<Domain> cavities;

  /// Default contsuctor
  Domain(this.type, [List<Domain> _cavities])
      : cavities = _cavities != null ? _cavities : new List<Domain>();

  /// Create [Domain] from a [DomainType] and an array of dimensions.
  factory Domain.fromType(DomainType type, Float32List dims) {
    switch (type) {
      case DomainType.box:
        return new BoxDomain.fromDims(dims);
      case DomainType.ellipsoid:
        return new EllipsoidDomain.fromDims(dims);
      default:
        return null;
    }
  }

  /// Add a new cavity.
  void addCavity(Domain cavity) => cavities.add(cavity);

  /// Get dimensions as floating point array.
  Float32List getDims();

  /// Get bounding box.
  BoxDomain computeBoundingBox();

  /// Compute a random point within the domain.
  Vector3 computeRandomPoint(Random rng) {
    // The default implementation uses containsPoint and computeBoundingBox.
    var point = new Vector3.zero();
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

  /// Check if the given coordinates are contained in this domain.
  /// Points that touch the domain surface are also contained.
  bool contains(num x, num y, num z) {
    if (_contains(x, y, z)) {
      for (var i = 0; i < cavities.length; i++) {
        if (cavities[i].contains(x, y, z)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  /// Check if the given coordinates are contained in this domain.
  /// Points that touch the domain surface are also contained.
  bool _contains(num x, num y, num z);

  /// Generate a GL_LINES wireframe outlining this domain.
  Float32List computeWireframe();

  /// Generate a GL_TRIANGLES polygon outlining this domain.
  Float32List computePolygon();
}

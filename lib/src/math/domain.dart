// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Available [Domain] types
enum DomainType { aabb, ellipsoid }

/// A particle domain for the BromiumEngine
abstract class Domain {
  /// The domain type
  final DomainType type;

  /// Cavities in the domain
  final List<Domain> cavities;

  Domain(this.type, [List<Domain> _cavities])
      : cavities = _cavities != null ? _cavities : new List<Domain>();

  /// Create [Domain] from the given [type] and [dims].
  factory Domain.fromBuffer(DomainType type, ByteBuffer buffer, int offset) {
    switch (type) {
      case DomainType.aabb:
        return new AabbDomain.fromBuffer(buffer, offset);
      case DomainType.ellipsoid:
        return new EllipsoidDomain.fromBuffer(buffer, offset);
      default:
        return null;
    }
  }

  /// Add a new cavity.
  void addCavity(Domain cavity) => cavities.add(cavity);

  /// Compute bounding box.
  Aabb3 computeBoundingBox();

  /// Compute a random point within the domain.
  /// The default implementation uses [computeBoundingBox] and [contains].
  Vector3 computeRandomPoint(Random rng) {
    var point = new Vector3.zero();
    var bbox = computeBoundingBox();
    do {
      point = bbox.min + randomVector3(rng)..dot(bbox.max - bbox.min);
    } while (!contains(point));
    return point;
  }

  /// Check if the given point is contained in this domain.
  bool contains(Vector3 point, {includeCavities: true}) {
    if (_contains(point)) {
      if (includeCavities) {
        for (var cavity in cavities) {
          if (cavity.contains(point)) {
            return false;
          }
        }
      }
      return true;
    } else {
      return false;
    }
  }

  /// Internal method for [contains]
  bool _contains(Vector3 point);

  /// Find ray intersections.
  List<double> computeRayIntersections(Ray ray, {includeCavities: true}) {
    var intersections = _computeRayIntersections(ray);
    if (includeCavities) {
      for (var cavity in cavities) {
        intersections.addAll(cavity.computeRayIntersections(ray));
      }
    }
    return intersections;
  }

  /// Internal method for [computeRayIntersections]
  List<double> _computeRayIntersections(Ray ray);

  /// Generate a GL_LINES wireframe outlining this domain.
  List<Vector3> generateWireframe({includeCavities: true}) {
    var vertices = new List<Vector3>();
    vertices.addAll(_generateWireframe());
    if (includeCavities) {
      for (var cavity in cavities) {
        vertices.addAll(cavity.generateWireframe());
      }
    }
    return vertices;
  }

  /// Internal method for [generateWireframe]
  List<Vector3> _generateWireframe();

  /// Generate a GL_TRIANGLES polygon outlining this domain.
  List<Vector3> generatePolygonMesh({includeCavities: true}) {
    var vertices = new List<Vector3>();
    vertices.addAll(_generatePolygonMesh());
    if (includeCavities) {
      for (var cavity in cavities) {
        vertices.addAll(cavity.generatePolygonMesh());
      }
    }
    return vertices;
  }

  /// Internal method for [generatePolygonMesh]
  List<Vector3> _generatePolygonMesh();
}

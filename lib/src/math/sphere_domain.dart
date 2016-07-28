// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Sphere domain
class SphereDomain extends Domain {
  /// Center
  Vector3 center;

  /// Sphere radius
  double radius;

  SphereDomain(this.center, this.radius) : super(DomainType.sphere);

  factory SphereDomain.fromBuffer(ByteBuffer buffer, int offset) {
    return new SphereDomain(new Vector3.fromBuffer(buffer, offset),
        buffer.asFloat32List(offset + 12, 1).first);
  }

  String toString() =>
      'spherical domain {center: ${center.toString()}, radius: $radius}';

  int get _sizeInBytes => center.storage.lengthInBytes + 4;

  int _transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    center = transferVector3(buffer, offset, copy, center);
    offset += center.storage.lengthInBytes;

    final radiusView = new Float32View(buffer, offset);
    if (copy) {
      radiusView.set(radius);
    } else {
      radius = radiusView.get();
    }

    offset += radiusView.sizeInBytes;
    return offset;
  }

  Aabb3 computeBoundingBox() => new Aabb3.minMax(
      new Vector3.all(-radius)..add(center),
      new Vector3.all(radius)..add(center));

  bool contains(Vector3 point) {
    return (point - center).length < radius;
  }

  double minSurfaceToPoint(Vector3 point) {
    return ((point - center).length - radius).abs();
  }

  List<double> computeRayIntersections(Ray ray) => computeRaySphereIntersection(
      ray, new Sphere.centerRadius(center, radius));
}

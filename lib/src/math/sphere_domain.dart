// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Sphere domain
class SphereDomain extends Domain {
  /// Center
  @override
  Vector3 center;

  /// Sphere radius
  double radius;

  SphereDomain(this.center, this.radius) : super(DomainType.sphere);

  factory SphereDomain.fromBuffer(ByteBuffer buffer, int offset) {
    return new SphereDomain(new Vector3.fromBuffer(buffer, offset),
        buffer.asFloat32List(offset + 12, 1).first);
  }

  @override
  String toString() =>
      'spherical domain {center: ${center.toString()}, radius: $radius}';

  @override
  int get _sizeInBytes => center.storage.lengthInBytes + 4;

  @override
  int _transfer(ByteBuffer buffer, int offset, {bool copy: true}) {
    var _offset = offset;
    center = transferVector3(buffer, _offset, center, copy: copy);
    _offset += center.storage.lengthInBytes;

    final radiusView = new Float32View(buffer, _offset);
    if (copy) {
      radiusView.set(radius);
    } else {
      radius = radiusView.get();
    }

    _offset += radiusView.sizeInBytes;
    return _offset;
  }

  @override
  Aabb3 computeBoundingBox() => new Aabb3.minMax(
      new Vector3.all(-radius)..add(center),
      new Vector3.all(radius)..add(center));

  @override
  bool contains(Vector3 point) {
    return (point - center).length < radius;
  }

  @override
  double minSurfaceToPoint(Vector3 point) {
    return ((point - center).length - radius).abs();
  }

  @override
  List<double> computeRayIntersections(Ray ray) => computeRaySphereIntersection(
      ray, new Sphere.centerRadius(center, radius));
}

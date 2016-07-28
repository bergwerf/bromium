// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Ellipsoid domain
class EllipsoidDomain extends Domain {
  /// Center
  Vector3 center;

  /// Semi-axis sizes
  Vector3 _semiAxes;

  /// Min and max semi-axis (to boost [minSurfaceToPoint])
  double _semiAxisMin, _semiAxisMax;

  EllipsoidDomain(this.center, Vector3 _semiAxes)
      : super(DomainType.ellipsoid) {
    semiAxes = _semiAxes;
  }

  factory EllipsoidDomain.fromBuffer(ByteBuffer buffer, int offset) {
    return new EllipsoidDomain(
        new Vector3.fromBuffer(buffer, offset),
        new Vector3.fromBuffer(
            buffer, offset + Float32List.BYTES_PER_ELEMENT * 3));
  }

  // Semi-axis public get/set
  Vector3 get semiAxes => _semiAxes;
  set semiAxes(Vector3 values) {
    _semiAxes = values;
    _semiAxisMin = _semiAxes.storage.reduce(min);
    _semiAxisMax = _semiAxes.storage.reduce(max);
  }

  String toString() =>
      'ellipsoid domain {center: ${center.toString()}, semiAxes: ${semiAxes.toString()}}';

  int get _sizeInBytes =>
      center.storage.lengthInBytes + semiAxes.storage.lengthInBytes;

  int _transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    center = transferVector3(buffer, offset, copy, center);
    offset += center.storage.lengthInBytes;
    semiAxes = transferVector3(buffer, offset, copy, semiAxes);
    offset += semiAxes.storage.lengthInBytes;
    return offset;
  }

  Aabb3 computeBoundingBox() =>
      new Aabb3.minMax(center - semiAxes, center + semiAxes);

  bool contains(Vector3 point) {
    final p = point - center;
    return p.x * p.x / (semiAxes.x * semiAxes.x) +
            p.y * p.y / (semiAxes.y * semiAxes.y) +
            p.z * p.z / (semiAxes.z * semiAxes.z) <
        1;
  }

  double minSurfaceToPoint(Vector3 point) {
    final distance = (point - center).length;
    return distance > _semiAxisMax
        ? distance - _semiAxisMax
        : (distance < _semiAxisMin ? _semiAxisMin - distance : 0);
  }

  List<double> computeRayIntersections(Ray ray) =>
      computeRayEllipsoidIntersection(ray, this);
}

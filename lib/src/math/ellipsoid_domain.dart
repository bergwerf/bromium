// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Ellipsoid domain
class EllipsoidDomain extends Domain {
  /// Center
  Vector3 center;

  /// Semi-axis sizes
  Vector3 semiAxes;

  EllipsoidDomain(this.center, this.semiAxes) : super(DomainType.ellipsoid);

  /// Construct from buffer.
  factory EllipsoidDomain.fromBuffer(ByteBuffer buffer, int offset) {
    return new EllipsoidDomain(
        new Vector3.fromBuffer(buffer, offset),
        new Vector3.fromBuffer(
            buffer, offset + Float32List.BYTES_PER_ELEMENT * 3));
  }

  int get _sizeInBytes =>
      center.storage.lengthInBytes + semiAxes.storage.lengthInBytes;

  int _transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    // Create views.
    var _center = new Vector3.fromBuffer(buffer, offset);
    offset += center.storage.lengthInBytes;
    var _semiAxes = new Vector3.fromBuffer(buffer, offset);

    // Copy old data into new buffer.
    if (copy) {
      _center.copyFromArray(center.storage);
      _semiAxes.copyFromArray(semiAxes.storage);
    }

    // Replace local data.
    center = _center;
    semiAxes = _semiAxes;

    return offset + semiAxes.storage.lengthInBytes;
  }

  Aabb3 computeBoundingBox() =>
      new Aabb3.minMax(center - semiAxes, center + semiAxes);

  bool contains(Vector3 point) {
    /// Good looking but probably slower alternative:
    ///
    ///     final v = point.clone() - center;
    ///     v.multiply(v);
    ///     final a = semiAxes.clone()..multiply(semiAxes);
    ///     return v.dot(new Vector3.all(1.0)..divide(a)) < 1;
    ///

    final p = point.clone() - center;
    return p.x * p.x / (semiAxes.x * semiAxes.x) +
            p.y * p.y / (semiAxes.y * semiAxes.y) +
            p.z * p.z / (semiAxes.z * semiAxes.z) <
        1;
  }

  List<double> computeRayIntersections(Ray ray) =>
      computeRayEllipsoidIntersection(ray, this);
}

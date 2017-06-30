// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// AABB domain
class AabbDomain extends Domain {
  /// AABB data (from vector_math)
  Aabb3 data;

  AabbDomain(this.data) : super(DomainType.aabb);

  factory AabbDomain.fromBuffer(ByteBuffer buffer, int offset) =>
      new AabbDomain(new Aabb3.fromBuffer(buffer, offset));

  /// Construct AABB domain that contains all the given domains.
  factory AabbDomain.enclose(List<Domain> domains) {
    if (domains.isEmpty) {
      throw new ArgumentError.value(domains, 'domains', 'cannot be empty');
    } else {
      var aabb = domains.first.computeBoundingBox();
      final min = aabb.min;
      final max = aabb.max;
      for (var i = 1; i < domains.length; i++) {
        aabb = domains[i].computeBoundingBox();
        Vector3.min(aabb.min, min, min);
        Vector3.max(aabb.max, max, max);
      }
      return new AabbDomain(new Aabb3.minMax(min, max));
    }
  }

  @override
  String toString() =>
      'AABB domain {min: ${data.min.toString()}, max: ${data.max.toString()}}';

  @override
  int get _sizeInBytes =>
      data.min.storage.lengthInBytes + data.max.storage.lengthInBytes;

  @override
  int _transfer(ByteBuffer buffer, int offset, {bool copy: true}) {
    data = copy
        ? (new Aabb3.fromBuffer(buffer, offset)..copyFrom(data))
        : new Aabb3.fromBuffer(buffer, offset);
    return offset +
        data.min.storage.lengthInBytes +
        data.max.storage.lengthInBytes;
  }

  @override
  Aabb3 computeBoundingBox() => data;

  @override
  bool contains(Vector3 point) => data.containsVector3(point);

  @override
  double minSurfaceToPoint(Vector3 point) {
    return [
      (data.min.x - point.x).abs(),
      (data.min.y - point.y).abs(),
      (data.min.z - point.z).abs(),
      (data.max.x - point.x).abs(),
      (data.max.y - point.y).abs(),
      (data.max.z - point.z).abs()
    ].reduce(min);
  }

  @override
  List<double> computeRayIntersections(Ray ray) =>
      computeRayAabbIntersections(ray, data);
}

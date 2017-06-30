// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Available [Domain] types
enum DomainType { aabb, sphere, ellipsoid }

/// A particle domain for the BromiumEngine
abstract class Domain implements Transferrable {
  /// The domain type
  DomainType type;

  Domain(this.type);

  /// Create [Domain] from the data in [buffer] at [offset].
  factory Domain.fromBuffer(ByteBuffer buffer, int offset) {
    // Resolve the domain type.
    final typeView = new Uint32View(buffer, offset);
    final type = DomainType.values[typeView.get()];
    offset += Uint32View.byteCount;

    // Construct the specific domain.
    switch (type) {
      case DomainType.aabb:
        return new AabbDomain.fromBuffer(buffer, offset);
      case DomainType.sphere:
        return new SphereDomain.fromBuffer(buffer, offset);
      case DomainType.ellipsoid:
        return new EllipsoidDomain.fromBuffer(buffer, offset);
      default:
        return null;
    }
  }

  /// Get center.
  Vector3 get center => computeBoundingBox().center;

  /// Compute bounding box.
  Aabb3 computeBoundingBox();

  /// Compute a random point within the domain.
  /// The default implementation uses [computeBoundingBox] and [contains].
  Vector3 computeRandomPoint({Random rng, List<Domain> cavities: const []}) {
    final _rng = rng ?? new Random();
    var point = new Vector3.zero();
    final bbox = computeBoundingBox();
    final diagonal = bbox.max - bbox.min;
    var containsPoint = false;

    do {
      point = bbox.min + (randomVector3(_rng)..multiply(diagonal));

      // Check if the domain contains the point and exclude cavities.
      containsPoint = contains(point);
      if (containsPoint && cavities.isNotEmpty) {
        for (final cavity in cavities) {
          if (cavity.contains(point)) {
            containsPoint = false;
            break;
          }
        }
      }
    } while (!containsPoint);

    return point;
  }

  /// Internal method for [contains]
  bool contains(Vector3 point);

  /// Estimate the minimum distance to go from the given [point] to any point on
  /// the surface. This can be the exact smallest distance or a lower boundary.
  /// The return value should always be a positive number.
  double minSurfaceToPoint(Vector3 point);

  /// Internal method for [computeRayIntersections]
  List<double> computeRayIntersections(Ray ray);

  /// General getter for the byte size
  @override
  int get sizeInBytes => Uint32View.byteCount + _sizeInBytes;

  /// General method for transferring the domain data
  @override
  int transfer(ByteBuffer buffer, int offset, {bool copy: true}) {
    final typeView = new Uint32View(buffer, offset);
    if (copy) {
      // Copy the domain type into a Uint32.
      typeView.set(type.index);
    } else {
      // Read the domain type from the buffer.
      type = DomainType.values[typeView.get()];
    }
    return _transfer(buffer, offset + Uint32View.byteCount);
  }

  /// Membrane specific additional byte size
  int get _sizeInBytes;

  /// Membrane specific transfer method
  int _transfer(ByteBuffer buffer, int offset, {bool copy: true});
}

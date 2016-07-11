// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Available [Domain] types
enum DomainType { aabb, ellipsoid }

/// A particle domain for the BromiumEngine
abstract class Domain implements Transferrable {
  /// The domain type
  final DomainType type;

  Domain(this.type);

  /// Create [Domain] from the data in [buffer] at [offset].
  factory Domain.fromBuffer(ByteBuffer buffer, int offset) {
    // Resolve the domain type.
    var typeView = new Uint32View(buffer, offset);
    var type = DomainType.values[typeView.get()];
    offset += Uint32View.byteCount;

    // Construct the specific domain.
    switch (type) {
      case DomainType.aabb:
        return new AabbDomain.fromBuffer(buffer, offset);
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
  Vector3 computeRandomPoint([Random rng, List<Domain> cavities]) {
    rng = rng == null ? new Random() : rng;
    var point = new Vector3.zero();
    var bbox = computeBoundingBox();
    var diagonal = bbox.max - bbox.min;
    bool containsPoint = false;

    do {
      point = bbox.min + (randomVector3(rng)..multiply(diagonal));

      // Check if the domain contains the point and exclude cavities.
      containsPoint = contains(point);
      if (containsPoint && cavities != null) {
        for (var cavity in cavities) {
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

  /// Internal method for [computeRayIntersections]
  List<double> computeRayIntersections(Ray ray);

  /// General getter for the byte size
  int get sizeInBytes => Uint32View.byteCount + _sizeInBytes;

  /// General method for transferring the domain data
  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    /// Copy the domain type into a Uint32.
    var typeView = new Uint32View(buffer, offset);
    typeView.set(type.index);
    return _transfer(buffer, offset + Uint32View.byteCount);
  }

  /// Membrane specific additional byte size
  int get _sizeInBytes;

  /// Membrane specific transfer method
  int _transfer(ByteBuffer buffer, int offset, [bool copy = true]);
}

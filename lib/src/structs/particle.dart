// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Particle information
///
/// Only [type] and [position] are included in the binary stream. The
/// [entered] array is only used for optimization.
class Particle implements Transferrable {
  /// Number of floats each particle allocates in a byte buffer
  static const floatCount = 7;

  /// Number of bytes each particle allocates in a byte buffer
  static const byteCount = Float32List.BYTES_PER_ELEMENT * floatCount;

  /// Type
  final int type;

  /// Position
  Vector3 position;

  /// Display color
  Vector3 color;

  /// Display radius
  Float32View radius;

  /// List containing all entered membranes
  final List<int> entered;

  /// Environment membrane; the particle has the same average motion as this
  /// membrane.
  int envMembrane = -1;

  Particle(this.type, this.position, this.color, double radius)
      : radius = new Float32View.value(radius),
        entered = [];

  int get sizeInBytes => byteCount;
  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    // Create new views.
    var _position = new Vector3.fromBuffer(buffer, offset);
    offset += position.storage.lengthInBytes;
    var _color = new Vector3.fromBuffer(buffer, offset);
    offset += color.storage.lengthInBytes;
    offset = radius.transfer(buffer, offset, copy);

    // Copy old data into new buffer.
    if (copy) {
      _position.copyFromArray(position.storage);
      _color.copyFromArray(color.storage);
    }

    // Replace local data.
    position = _position;
    color = _color;

    return offset;
  }
}

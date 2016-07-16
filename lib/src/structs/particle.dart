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
  static const floatCount = 8;

  /// Number of bytes each particle allocates in a byte buffer
  static const byteCount = Float32List.BYTES_PER_ELEMENT * floatCount;

  /// Type
  int type;

  /// Position
  Vector3 position;

  /// Display color
  Vector3 color;

  /// Display radius
  Float32View displayRadius;

  /// Step radius
  Float32View stepRadius;

  /// List containing all entered membranes
  final List<int> entered;

  /// Stick membrane. If the particle is sticked to a membrane this integer is
  /// set to the membrane index. Else it is set to -1.
  int sticked;

  Particle(this.type, this.position, this.color, double displayRadius,
      double stepRadius)
      : displayRadius = new Float32View.value(displayRadius),
        stepRadius = new Float32View.value(stepRadius),
        entered = new List<int>();

  Particle.raw(this.type, this.position, this.color, this.displayRadius,
      this.stepRadius, this.entered);

  /// Copy the given position into the position view.
  void setPosition(Vector3 _position) {
    position.copyFromArray(_position.storage);
  }

  /// Copy the given color into the color view.
  void setColor(Vector3 _color) {
    color.copyFromArray(_color.storage);
  }

  int get sizeInBytes => byteCount;
  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    position = transferVector3(buffer, offset, copy, position);
    offset += position.storage.lengthInBytes;
    color = transferVector3(buffer, offset, copy, color);
    offset += color.storage.lengthInBytes;
    offset = displayRadius.transfer(buffer, offset, copy);
    offset = stepRadius.transfer(buffer, offset, copy);
    return offset;
  }
}

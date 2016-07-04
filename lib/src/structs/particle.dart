// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Particle information
///
/// Only [type] and [position] are included in the binary stream. The
/// [entered] array is only used for optimization.
class Particle implements Transferrable {
  /// Number of bytes each particle allocates in a byte buffer
  static const byteCount =
      Uint16View.byteCount + Float32List.BYTES_PER_ELEMENT * 3;

  /// Type
  final Uint16View _type;

  /// Position
  Vector3 position;

  /// List containing all entered membranes.
  final List<int> entered;

  Particle(this._type, this.position) : entered = [];

  int get type => _type.get();
  set type(int value) => _type.set(value);

  int get sizeInBytes => byteCount;
  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    offset += _type.transfer(buffer, offset, copy);
    position = copy
        ? (new Vector3.fromBuffer(buffer, offset)
          ..copyFromArray(position.storage))
        : new Vector3.fromBuffer(buffer, offset);
    return offset + position.storage.lengthInBytes;
  }
}

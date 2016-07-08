// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Simulation metadata that is contained in the first part of the render
/// buffer.
class SimulationHeader implements Transferrable {
  /// Number of bytes allocated by the simulation header
  static const byteCount = length * Uint32List.BYTES_PER_ELEMENT;

  /// Header data
  Uint32List data;

  // Dimension data
  static const _bindReactionCount = 0,
      _unbindReactionCount = 1,
      _particleCount = 2,
      _membranesOffset = 3,
      _membraneCount = 4,
      length = 5;

  SimulationHeader(int bindReactionCount, int unbindReactionCount) {
    data = new Uint32List(length);
    data[_bindReactionCount] = bindReactionCount;
    data[_unbindReactionCount] = unbindReactionCount;
  }

  /// Creates empty header and transfer to the given buffer.
  SimulationHeader.fromBuffer(ByteBuffer buffer, int offset) {
    transfer(buffer, offset, false);
  }

  int get sizeInBytes => byteCount;
  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    data = copy
        ? (new Uint32List.view(buffer, offset, length)..setAll(0, data))
        : new Uint32List.view(buffer, offset, length);
    return offset + byteCount;
  }

  int get bindReactionCount => data[_bindReactionCount];
  int get unbindReactionCount => data[_unbindReactionCount];
  int get particleCount => data[_particleCount];
  set particleCount(int value) => data[_particleCount] = value;
  int get membranesOffset => data[_membranesOffset];
  set membranesOffset(int value) => data[_membranesOffset] = value;
  int get membraneCount => data[_membraneCount];
  set membraneCount(int value) => data[_membraneCount] = value;
}

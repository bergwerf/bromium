// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Membrane information
///
/// All membrane information is included in the binary stream.
class Membrane implements Transferrable {
  /// Membrane volume
  final Domain domain;

  /// Inward flux fraction that is allowed per type
  Float32List ffIn;

  /// Outward flux fraction that is allowed per type
  Float32List ffOut;

  /// Contained number of particles per type
  Uint32List concentrations;

  Membrane(this.domain, this.ffIn, this.ffOut, int particleCount)
      : concentrations = new Uint32List(particleCount);

  int get sizeInBytes =>
      domain.sizeInBytes +
      ffIn.lengthInBytes +
      ffOut.lengthInBytes +
      concentrations.lengthInBytes;

  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    // Create new views.
    offset = domain.transfer(buffer, offset, copy);
    var _ffIn = new Float32List.view(buffer, offset);
    offset += ffIn.lengthInBytes;
    var _ffOut = new Float32List.view(buffer, offset);
    offset += ffOut.lengthInBytes;
    var _concentrations = new Uint32List.view(buffer, offset);

    // Copy old data into new buffer.
    if (copy) {
      _ffIn.setAll(0, ffIn);
      _ffOut.setAll(0, ffOut);
      _concentrations.setAll(0, concentrations);
    }

    // Replace local data.
    ffIn = _ffIn;
    ffOut = _ffOut;
    concentrations = _concentrations;

    return offset + concentrations.lengthInBytes;
  }
}

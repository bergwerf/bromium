// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Membrane information
///
/// All membrane information is included in the binary stream.
class Membrane implements Transferrable {
  /// Relative to membrane locations
  static const inside = 0;
  static const sticked = 1;
  static const outside = 2;

  /// Membrane volume
  final Domain domain;

  /// Inward pass allowance
  Float32List passIn;

  /// Outward pass allowance
  Float32List passOut;

  /// Inward stick allowance
  /// TODO: implement in buffer and kinetics
  Float32List stickIn;

  /// Outward stick allowance
  /// TODO: implement in buffer and kinetics
  Float32List stickOut;

  /// Contained number of particles per type
  /// TODO: implement in kinetics
  Uint32List insideCount;

  /// Sticked number of particles per type
  /// TODO: implement in buffer and kinetics
  Uint32List stickedCount;

  /// Membrane movement vector
  Vector3 speed = new Vector3.zero();

  Membrane(this.domain, this.passIn, this.passOut, this.stickIn, this.stickOut,
      int particleCount)
      : insideCount = new Uint32List(particleCount);

  int get sizeInBytes =>
      domain.sizeInBytes +
      passIn.lengthInBytes +
      passOut.lengthInBytes +
      insideCount.lengthInBytes;

  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    // Create new views.
    offset = domain.transfer(buffer, offset, copy);
    var _passIn = new Float32List.view(buffer, offset);
    offset += passIn.lengthInBytes;
    var _passOut = new Float32List.view(buffer, offset);
    offset += passOut.lengthInBytes;
    var _concentrations = new Uint32List.view(buffer, offset);

    // Copy old data into new buffer.
    if (copy) {
      _passIn.setAll(0, passIn);
      _passOut.setAll(0, passOut);
      _concentrations.setAll(0, insideCount);
    }

    // Replace local data.
    passIn = _passIn;
    passOut = _passOut;
    insideCount = _concentrations;

    return offset + insideCount.lengthInBytes;
  }
}

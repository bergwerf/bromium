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
  /// TODO: implement in kinetics
  Float32List stickIn;

  /// Outward stick allowance
  /// TODO: implement in kinetics
  Float32List stickOut;

  /// Contained number of particles per type
  /// TODO: implement in kinetics
  Uint32List insideCount;

  /// Sticked number of particles per type
  /// TODO: implement in kinetics
  Uint32List stickedCount;

  /// Membrane movement vector
  Vector3 speed = new Vector3.zero();

  Membrane(this.domain, this.passIn, this.passOut, this.stickIn, this.stickOut,
      int particleCount)
      : insideCount = new Uint32List(particleCount),
        stickedCount = new Uint32List(particleCount);

  int get sizeInBytes =>
      domain.sizeInBytes +
      passIn.lengthInBytes +
      passOut.lengthInBytes +
      stickIn.lengthInBytes +
      stickOut.lengthInBytes +
      insideCount.lengthInBytes +
      stickedCount.lengthInBytes;

  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    offset = domain.transfer(buffer, offset, copy);
    passIn = transferFloat32List(buffer, offset, copy, passIn);
    offset += passIn.lengthInBytes;
    passOut = transferFloat32List(buffer, offset, copy, passOut);
    offset += passOut.lengthInBytes;
    stickIn = transferFloat32List(buffer, offset, copy, stickIn);
    offset += stickIn.lengthInBytes;
    stickOut = transferFloat32List(buffer, offset, copy, stickOut);
    offset += stickOut.lengthInBytes;
    insideCount = transferUint32List(buffer, offset, copy, insideCount);
    offset += insideCount.lengthInBytes;
    stickedCount = transferUint32List(buffer, offset, copy, stickedCount);
    offset += stickedCount.lengthInBytes;
    return offset;
  }
}

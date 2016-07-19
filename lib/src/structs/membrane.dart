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

  /// Enter probability per particle type
  Float32List enterP;

  /// Leave probability per particle type
  Float32List leaveP;

  /// Stick on enter probability per particle type
  Float32List enterStickP;

  /// Stick on leave probability per particle type
  Float32List leaveStickP;

  /// Contained number of particles per type
  Uint32List insideCount;

  /// Sticked number of particles per type
  Uint32List stickedCount;

  /// Membrane movement vector
  Vector3 speed = new Vector3.zero();

  Membrane(this.domain, this.enterP, this.leaveP, this.enterStickP,
      this.leaveStickP, int particleCount)
      : insideCount = new Uint32List(particleCount),
        stickedCount = new Uint32List(particleCount);

  /// Decide if the given particle type sticks.
  bool stick(int type, bool enters, bool leaves) {
    if (enters) {
      return enterStickP[type] == 0 ? false : rand() < enterStickP[type];
    } else if (leaves) {
      return leaveStickP[type] == 0 ? false : rand() < leaveStickP[type];
    } else {
      return false;
    }
  }

  /// Decide if the given particle type may enter.
  bool mayEnter(int type) => enterP[type] == 0 ? false : rand() < enterP[type];

  /// Decide if the given particle type may leave.
  bool mayLeave(int type) => leaveP[type] == 0 ? false : rand() < leaveP[type];

  int get sizeInBytes =>
      domain.sizeInBytes +
      enterP.lengthInBytes +
      leaveP.lengthInBytes +
      enterStickP.lengthInBytes +
      leaveStickP.lengthInBytes +
      insideCount.lengthInBytes +
      stickedCount.lengthInBytes;

  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    offset = domain.transfer(buffer, offset, copy);
    enterP = transferFloat32List(buffer, offset, copy, enterP);
    offset += enterP.lengthInBytes;
    leaveP = transferFloat32List(buffer, offset, copy, leaveP);
    offset += leaveP.lengthInBytes;
    enterStickP = transferFloat32List(buffer, offset, copy, enterStickP);
    offset += enterStickP.lengthInBytes;
    leaveStickP = transferFloat32List(buffer, offset, copy, leaveStickP);
    offset += leaveStickP.lengthInBytes;
    insideCount = transferUint32List(buffer, offset, copy, insideCount);
    offset += insideCount.lengthInBytes;
    stickedCount = transferUint32List(buffer, offset, copy, stickedCount);
    offset += stickedCount.lengthInBytes;
    return offset;
  }
}

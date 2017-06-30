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

  /// Membrane index
  int index;

  /// Enter probability per particle type
  Float32List enterP;

  /// Leave probability per particle type
  Float32List leaveP;

  /// Stick on enter probability per particle type
  Float32List enterStickP;

  /// Stick on leave probability per particle type
  Float32List leaveStickP;

  /// Contained number of particles per type
  Uint32List _enteredCount;

  /// Sticked number of particles per type
  ///
  /// Note that sticked particles should NOT be included in the entered count!
  Uint32List _stickedCount;

  /// Membrane movement vector
  ///
  /// Membrane dynamics have not yet been implemented. However, here is an idea
  /// on what to do with particles inside the membrane when it is moving: move
  /// all particles with the same ammount as the membrane each cycle. This will
  /// make sure there are no collisions with inner particles, and it retains the
  /// particle random motion relative to the membrane.
  Vector3 speed = new Vector3.zero();

  Membrane(this.domain, this.enterP, this.leaveP, this.enterStickP,
      this.leaveStickP, int particleCount)
      : _enteredCount = new Uint32List(particleCount),
        _stickedCount = new Uint32List(particleCount);

  // Public read access for entered and sticked counts.
  //get Uint32List enteredCount => _enteredCount;
  //get Uint32List enteredCount => _enteredCount;

  /// Decide if the given particle type sticks.
  bool stick(int type, {bool enters, bool leaves}) {
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

  /// Decrement entered particle count at [type].
  int decrementEntered(int type) => _enteredCount[type]--;

  /// Decrement sticked particle count at [type].
  int decrementSticked(int type) => _stickedCount[type]--;

  /// Enter particle.
  void enterParticleUnsafe(Particle particle) {
    particle.pushEntered(index);
    _enteredCount[particle.type]++;
  }

  /// Leave particle.
  void leaveParticleUnsafe(Particle particle) {
    particle.popEntered(index);
    decrementEntered(particle.type);
  }

  /// Stick particle.
  void stickParticleUnsafe(Particle particle, {bool doProjection: true}) {
    particle.stickTo(index, domain, doProjection: doProjection);
    _stickedCount[particle.type]++;
  }

  /// Unstick particle.
  void unstickParticleUnsafe(Particle particle) {
    decrementSticked(particle.type);
    particle.sticked = -1;
  }

  /// Update entered count after changing the type of an entered particle.
  void changeEnteredType(int from, int to) {
    _enteredCount[from]--;
    _enteredCount[to]++;
  }

  /// Update entered count after changing the type of a sticked particle.
  void changeStickedType(int from, int to) {
    _stickedCount[from]--;
    _stickedCount[to]++;
  }

  @override
  int get sizeInBytes =>
      domain.sizeInBytes +
      enterP.lengthInBytes +
      leaveP.lengthInBytes +
      enterStickP.lengthInBytes +
      leaveStickP.lengthInBytes +
      _enteredCount.lengthInBytes +
      _stickedCount.lengthInBytes;

  @override
  int transfer(ByteBuffer buffer, int offset, {bool copy: true}) {
    var _offset = domain.transfer(buffer, offset, copy: copy);
    enterP = transferFloat32List(buffer, _offset, copy, enterP);
    _offset += enterP.lengthInBytes;
    leaveP = transferFloat32List(buffer, _offset, copy, leaveP);
    _offset += leaveP.lengthInBytes;
    enterStickP = transferFloat32List(buffer, _offset, copy, enterStickP);
    _offset += enterStickP.lengthInBytes;
    leaveStickP = transferFloat32List(buffer, _offset, copy, leaveStickP);
    _offset += leaveStickP.lengthInBytes;
    _enteredCount = transferUint32List(buffer, _offset, copy, _enteredCount);
    _offset += _enteredCount.lengthInBytes;
    _stickedCount = transferUint32List(buffer, _offset, copy, _stickedCount);
    _offset += _stickedCount.lengthInBytes;
    return _offset;
  }
}

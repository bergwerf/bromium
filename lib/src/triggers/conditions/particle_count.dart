// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Trigger condition that retrieves the specified particle [type] from the
/// specified [membrane] and compares it to [count] using [condition].
class ParticleCountCondition extends TriggerCondition {
  final int count;

  final int type;

  final int membrane;

  final int condition;

  ParticleCountCondition(this.count, this.type, this.membrane, this.condition);

  ParticleCountCondition.equal(this.count, this.type, this.membrane)
      : condition = 0;

  ParticleCountCondition.less(this.count, this.type, this.membrane)
      : condition = 1;

  ParticleCountCondition.lessOrEqual(this.count, this.type, this.membrane)
      : condition = 2;

  ParticleCountCondition.greater(this.count, this.type, this.membrane)
      : condition = 3;

  ParticleCountCondition.greaterOrEqual(this.count, this.type, this.membrane)
      : condition = 4;

  bool check(Simulation sim) {
    var c = sim.buffer.particleCountIn(type, membrane);
    switch (condition) {
      case 0:
        return c == count;
      case 1:
        return c < count;
      case 2:
        return c <= count;
      case 3:
        return c > count;
      case 4:
        return c >= count;
      default:
        return false;
    }
  }
}

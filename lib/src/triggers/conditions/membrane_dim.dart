// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class MembraneDim extends TriggerCondition {
  final int membrane;

  final int dim;

  final double value;

  final int condition;

  MembraneDim(this.membrane, this.dim, this.value, this.condition);

  MembraneDim.equal(this.membrane, this.dim, this.value) : condition = 0;

  MembraneDim.less(this.membrane, this.dim, this.value) : condition = 1;

  MembraneDim.lessOrEqual(this.membrane, this.dim, this.value) : condition = 2;

  MembraneDim.greater(this.membrane, this.dim, this.value) : condition = 3;

  MembraneDim.greaterOrEqual(this.membrane, this.dim, this.value)
      : condition = 4;

  bool check(Simulation sim) {
    var c = sim.buffer.getMembraneDims(membrane)[dim];
    switch (condition) {
      case 0:
        return c == value;
      case 1:
        return c < value;
      case 2:
        return c <= value;
      case 3:
        return c > value;
      case 4:
        return c >= value;
      default:
        return false;
    }
  }
}

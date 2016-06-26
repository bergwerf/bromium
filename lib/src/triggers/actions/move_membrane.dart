// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class MoveMembrane extends TriggerAction {
  final int membrane;

  final double xPerCycle, yPerCycle, zPerCycle;

  MoveMembrane(this.membrane, this.xPerCycle, this.yPerCycle, this.zPerCycle);

  void run(Simulation sim) {
    var dims = sim.buffer.getMembraneDims(membrane);
    dims[0] += xPerCycle;
    dims[1] += yPerCycle;
    dims[2] += zPerCycle;
    sim.buffer.setMembraneDims(membrane, dims);
  }
}

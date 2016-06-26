// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class MembranePermeability extends TriggerAction {
  final int membrane;

  final bool inwards;

  final int type;

  final double value;

  MembranePermeability(this.membrane, this.inwards, this.type, this.value);

  void run(Simulation sim) {
    if (inwards) {
      sim.buffer.setInwardPermeability(membrane, type, value);
    } else {
      sim.buffer.setOutwardPermeability(membrane, type, value);
    }
  }
}

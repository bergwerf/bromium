// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Base class for membranes
class Membrane {
  /// Membrane domain volume
  Domain domain;

  /// Probability of particles moving into the membrane
  Map<int, double> inwardPermeability;

  /// Probability of particles moving out of the membrane
  Map<int, double> outwardPermeability;

  /// Constructor
  Membrane(this.domain, this.inwardPermeability, this.outwardPermeability);
}

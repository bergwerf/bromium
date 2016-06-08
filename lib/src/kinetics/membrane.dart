// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Base class for membranes
class Membrane {
  /// Membrane domain volume
  Domain domain;

  /// Particles that can move into the membrane.
  List<int> inwardPermeability;

  /// Particles that can move out of the membrane.
  List<int> outwardPermeability;

  /// Constructor
  Membrane(this.domain, this.inwardPermeability, this.outwardPermeability);

  /// Compute if the given displacement due to random motion should be blocked
  /// because this membrane is passed while it is not permeable in that
  /// direction for the given particle.
  bool blockParticleMotion(
      int particleType, Vector3 position, Vector3 displacement) {}
}

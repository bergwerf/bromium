// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Data structure for A + B -> C style reactions
class BindReaction {
  /// Particle A
  final int particleA;

  /// Particle B
  final int particleB;

  /// Particle C
  final int particleC;

  /// Reaction probability on hit
  final double p;

  /// Constructor
  BindReaction(this.particleA, this.particleB, this.particleC, this.p);
}

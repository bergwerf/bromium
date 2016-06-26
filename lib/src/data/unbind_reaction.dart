// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Data structure for A -> B + C + ... style reactions
class UnbindReaction {
  /// Particle A label
  final int particleA;

  /// Reaction products
  final List<int> products;

  /// Reaction probability
  final double p;

  /// Constructor
  UnbindReaction(this.particleA, this.products, this.p);
}

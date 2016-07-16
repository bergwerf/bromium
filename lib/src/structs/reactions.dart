// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Base class for reactions
///
/// Only reaction [probability] is included in the binary stream.
class Reaction implements Transferrable {
  /// Number of bytes each reaction allocates in a byte buffer
  static const byteCount = Float32View.byteCount;

  /// Bind probability on hit
  final Float32View _probability;

  Reaction(double probability)
      : _probability = new Float32View.value(probability);

  double get probability => _probability.get();
  set probability(double value) => _probability.set(value);

  int get sizeInBytes => byteCount;
  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) =>
      _probability.transfer(buffer, offset, copy);
}

/// Reaction particle
class ReactionParticle {
  /// Particle type
  int type;

  /// Particle location relative to the membrane
  /// TODO: implement in bind and unbind kinetics
  int relativeLocation;

  ReactionParticle(this.type, this.relativeLocation);
}

/// Data structure for A + B -> C style reactions
class BindReaction extends Reaction {
  /// Particle A
  final ReactionParticle particleA;

  /// Particle B
  final ReactionParticle particleB;

  /// Particle C
  final ReactionParticle particleC;

  BindReaction(
      this.particleA, this.particleB, this.particleC, double probability)
      : super(probability);
}

/// Data structure for A -> B + C + ... style reactions
class UnbindReaction extends Reaction {
  /// Particle A
  final ReactionParticle particleA;

  /// Reaction products
  final List<ReactionParticle> products;

  UnbindReaction(this.particleA, this.products, double probability)
      : super(probability);
}

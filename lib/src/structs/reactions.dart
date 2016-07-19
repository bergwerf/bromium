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
  int relativeLocation;

  ReactionParticle(this.type, this.relativeLocation);

  bool get inside => relativeLocation == Membrane.inside;
  bool get sticked => relativeLocation == Membrane.sticked;
  bool get outside => relativeLocation == Membrane.outside;
}

/// Data structure for A + B -> C style reactions
class BindReaction extends Reaction {
  /// Particle A
  ///
  /// The context membrane is resolved using this particle.
  final ReactionParticle particleA;

  /// Particle B
  final ReactionParticle particleB;

  /// Particle C
  final ReactionParticle particleC;

  BindReaction(
      this.particleA, this.particleB, this.particleC, double probability)
      : super(probability);

  /// Try if the given particle can react. This method does take the reaction
  /// probability and relative locations into account, but it does not take the
  /// reaction distance into account.
  ///
  /// Note that [a] should correspond to [particleA] and [b] to [particleB].
  bool tryReaction(Particle a, Particle b) {
    // This would indicate a fault in the kinetics algorithm.
    if (a.type != particleA.type || b.type != particleB.type) {
      throw new ArgumentError(
          '[a] should correspond to [particleA] and [b] to [particleB]');
    }

    // Proceed based on a random number and the reaction probability.
    if (probability == 1 || rand() < probability) {
      // Resolve context membrane.
      int membrane = -1;
      switch (particleA.relativeLocation) {
        case Membrane.inside:
          if (a.entered.isEmpty) {
            return false;
          }
          membrane = a.entered.last;
          break;

        case Membrane.sticked:
          if (!a.isSticked) {
            return false;
          }
          membrane = a.sticked;
          break;
      }

      // Check relative location of particle B.
      switch (particleB.relativeLocation) {
        case Membrane.inside:
          return b.entered.isEmpty ? false : b.entered.last == membrane;

        case Membrane.sticked:
          return !b.isSticked ? false : b.sticked == membrane;

        case Membrane.outside:
          return !b.hasEntered(membrane);
      }
    }
    return false;
  }
}

/// Bind reaction information for queueing reactions.
class BindReactionItem {
  // Particle A index, particle B index, reaction index.
  final int a, b, r;

  BindReactionItem(this.a, this.b, this.r);
}

/// Data structure for A -> B + C + ... style reactions
class UnbindReaction extends Reaction {
  /// Particle A
  ///
  /// The context membrane is resolved using this particle.
  final ReactionParticle particleA;

  /// Reaction products
  final List<ReactionParticle> products;

  UnbindReaction(this.particleA, this.products, double probability)
      : super(probability);
}

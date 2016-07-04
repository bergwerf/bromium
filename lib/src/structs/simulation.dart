// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// All information during a simulation. All data is final. All underlying
/// dynamic data is backed by the [buffer].
class Simulation {
  /// Buffer max size (300MB)
  static const maxBufferSize = 100000000;

  /// Buffer particles cap
  static const particlesCap = 10000;

  /// Buffer membranes cap
  static const membranesCapBytes = 100;

  /// Byte buffer for data that must be continously streamed to the frontend.
  /// (3D render input, some simulation state information)
  ByteBuffer buffer;

  /// Buffer header
  Uint32List bufferHeader;

  // Buffer header indices
  static const _bindReactionCount = 0,
      _unbindReactionCount = 1,
      _particleCount = 2,
      _membranesOffset = 3,
      _membraneCount = 4,
      _bufferHeaderLength = 5;

  /// Particle types
  final List<ParticleType> particleTypes;

  /// Bind reactions
  final List<BindReaction> bindReactions;

  /// Unbind reactions
  final List<UnbindReaction> unbindReactions;

  /// Particles
  final List<Particle> particles;

  /// Membranes
  final List<Membrane> membranes;

  /// Load simulation from loose data.
  Simulation(this.particleTypes, this.bindReactions, this.unbindReactions,
      this.particles, this.membranes) {
    // Transfer all data to a single byte buffer.
    transfer(0, 0);
  }

  int get bindReactionCount => bufferHeader[_bindReactionCount];
  int get unbindReactionCount => bufferHeader[_unbindReactionCount];
  int get particleCount => bufferHeader[_particleCount];
  set particleCount(int value) => bufferHeader[_particleCount] = value;
  int get membranesOffset => bufferHeader[_membranesOffset];
  set membranesOffset(int value) => bufferHeader[_membranesOffset] = value;
  int get membraneCount => bufferHeader[_membraneCount];
  set membraneCount(int value) => bufferHeader[_membraneCount] = value;

  /// Transfer all dynamic data to a new buffer. This method is primarily used
  /// to resize the byte buffer.
  void transfer(int addParticles, int addMembranes) {
    /// Buffer layout:
    /// - header variables
    ///   * number of bind reactions
    ///   * number of unbind reactions
    ///   * number of particles
    ///   * membrane buffer offset (due to particles cap)
    ///   * number of membranes
    /// - bind reaction probabilities
    /// - unbind reaction probabilities
    /// - particles + cap
    /// - membranes + cap

    // Compute new buffer size.
    var _membranesOffset = _bufferHeaderLength * Uint32List.BYTES_PER_ELEMENT +
        Reaction.byteCount * (bindReactions.length + unbindReactions.length) +
        Particle.byteCount * (particles.length + addParticles + particlesCap);

    var bufferSize = _membranesOffset;
    for (var membrane in membranes) {
      bufferSize += membrane.sizeInBytes;
    }
    bufferSize += membranesCapBytes;

    // Create new buffer.
    buffer = new ByteData(bufferSize).buffer;

    // Transfer header.
    bufferHeader = new Uint32List.view(buffer, 0, _bufferHeaderLength)
      ..setAll(0, bufferHeader);
    membranesOffset = _membranesOffset;

    // Transfer reactions and particles.
    var offset = _bufferHeaderLength;
    for (var bindReaction in bindReactions) {
      offset = bindReaction.transfer(buffer, offset);
    }
    for (var unbindReaction in unbindReactions) {
      offset = unbindReaction.transfer(buffer, offset);
    }
    for (var particle in particles) {
      offset = particle.transfer(buffer, offset);
    }

    // Skip particles cap and transfer membranes.
    offset = _membranesOffset;
    for (var membrane in membranes) {
      offset = membrane.transfer(buffer, offset);
    }
  }

  /// Update the [bufferHeader] values.
  void updateBufferHeader() {
    particleCount = particles.length;
    membraneCount = membranes.length;
  }
}

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
  static const membranesCapBytes = 120;

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

  /// Store particles offset in the buffer for convenience.
  int particlesOffset = 0;

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
  Simulation(this.particleTypes, this.bindReactions, this.unbindReactions)
      : particles = [],
        membranes = [] {
    // Set buffer header.
    bufferHeader = new Uint32List(_bufferHeaderLength);
    bufferHeader[_bindReactionCount] = bindReactions.length;
    bufferHeader[_unbindReactionCount] = unbindReactions.length;
    bufferHeader[_particleCount] = 0;
    bufferHeader[_membranesOffset] = 0;
    bufferHeader[_membraneCount] = 0;

    // Compute particles offset.
    particlesOffset = _bufferHeaderLength * Uint32List.BYTES_PER_ELEMENT +
        Reaction.byteCount * (bindReactions.length + unbindReactions.length);

    // Transfer all data to a single byte buffer.
    transfer(0, 0);
  }

  /// Add new particles by randomly generating [n] positions within [domain].
  void addRandomParticles(int type, Domain domain, int n) {
    _rescaleBuffer(n, 0);

    // Generate particles.
    for (; n > 0; n--) {
      _addParticle(new Particle(
          type, domain.computeRandomPoint(), particleTypes[type].color));
    }
  }

  /// Unsafe add particle to buffer.
  void _addParticle(Particle particle) {
    particle.transfer(
        buffer, particlesOffset + Particle.byteCount * particles.length);
    particles.add(particle);
  }

  /// Add a membrane to the buffer.
  void addMembrane(Membrane membrane) {
    _rescaleBuffer(0, membrane.sizeInBytes);
    membrane.transfer(buffer, membranesOffset + allMembraneBytes);
    membranes.add(membrane);
  }

  /// Compute bounding box that encloses all particles.
  Aabb3 particlesBoundingBox() {
    var _min = particles[0].position;
    var _max = particles[0].position;

    for (var p = 1; p < particles.length; p++) {
      Vector3.min(_min, particles[p].position, _min);
      Vector3.max(_max, particles[p].position, _max);
    }

    return new Aabb3.minMax(_min, _max);
  }

  /// Transfer all dynamic data to a new buffer. This method is primarily used
  /// to resize the byte buffer.
  void transfer(int addParticles, int addMembraneBytes) {
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
    bufferSize += allMembraneBytes + addMembraneBytes + membranesCapBytes;

    // Create new buffer.
    var newBuffer = new ByteData(bufferSize).buffer;

    // Transfer header.
    bufferHeader = new Uint32List.view(newBuffer, 0, _bufferHeaderLength)
      ..setAll(0, bufferHeader);
    membranesOffset = _membranesOffset;

    // Transfer reactions and particles.
    var offset = bufferHeader.lengthInBytes;
    for (var bindReaction in bindReactions) {
      offset = bindReaction.transfer(newBuffer, offset);
    }
    for (var unbindReaction in unbindReactions) {
      offset = unbindReaction.transfer(newBuffer, offset);
    }
    for (var particle in particles) {
      offset = particle.transfer(newBuffer, offset);
    }

    // Skip particles cap and transfer membranes.
    offset = _membranesOffset;
    for (var membrane in membranes) {
      offset = membrane.transfer(newBuffer, offset);
    }

    // Replace the local buffer.
    buffer = newBuffer;
  }

  int get allMembraneBytes {
    int count = 0;
    for (var membrane in membranes) {
      count += membrane.sizeInBytes;
    }
    return count;
  }

  /// Scale buffer so that it can contain the additional number of particles.
  void _rescaleBuffer(int addParticles, int addMembraneBytes) {
    // Check if enough buffer space is available and tranfer data to a larger
    // buffer if neccesary.

    if (addParticles > 0) {
      var finalParticlesOffset = particlesOffset +
          Particle.byteCount * (particles.length + addParticles);
      if (finalParticlesOffset < membranesOffset) {
        addParticles = 0;
      }
    }
    if (addMembraneBytes > 0) {
      var finalMembranesOffset =
          membranesOffset + allMembraneBytes + addMembraneBytes;
      if (finalMembranesOffset <= buffer.lengthInBytes) {
        addMembraneBytes = 0;
      }
    }

    if (addParticles != 0 || addMembraneBytes != 0) {
      transfer(addParticles, addMembraneBytes);
    }
  }

  /// Update the [bufferHeader] values.
  void updateBufferHeader() {
    particleCount = particles.length;
    membraneCount = membranes.length;
  }

  int get bindReactionCount => bufferHeader[_bindReactionCount];
  int get unbindReactionCount => bufferHeader[_unbindReactionCount];
  int get particleCount => bufferHeader[_particleCount];
  set particleCount(int value) => bufferHeader[_particleCount] = value;
  int get membranesOffset => bufferHeader[_membranesOffset];
  set membranesOffset(int value) => bufferHeader[_membranesOffset] = value;
  int get membraneCount => bufferHeader[_membraneCount];
  set membraneCount(int value) => bufferHeader[_membraneCount] = value;
}

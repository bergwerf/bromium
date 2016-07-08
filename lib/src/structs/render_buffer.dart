// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Class to read render data from binary simulation data
class RenderBuffer {
  /// Buffer data
  ByteBuffer buffer;

  /// Simulation header
  SimulationHeader header;

  /// Particles offset in the buffer
  int particlesOffset;

  /// Update the buffer data
  void update(ByteBuffer newBuffer) {
    buffer = newBuffer;
    header = new SimulationHeader.fromBuffer(newBuffer, 0);

    // Compute particles offset.
    particlesOffset = SimulationHeader.byteCount +
        Reaction.byteCount *
            (header.bindReactionCount + header.unbindReactionCount);
  }

  /// Get particle data view
  ///
  /// Particle positions are at offset = 0 and stride = 12
  /// Particle colors are at offset = 12 and stride = 12
  Float32List getParticleData() {
    return new Float32List.view(
        buffer, particlesOffset, header.particleCount * Particle.floatCount);
  }
}

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

  /// Get list of particle entered/sticked count data.
  List<Tuple2<Uint32List, Uint32List>> getParticleCounts() {
    var list = new List<Tuple2<Uint32List, Uint32List>>(header.membraneCount);
    var offset = header.membranesOffset;
    for (var i = 0; i < header.membraneCount; i++) {
      final domain = new Domain.fromBuffer(buffer, offset);
      offset += domain.sizeInBytes;
      offset += 4 * header.particleTypeCount;

      // Get entered particle counting.
      final enteredCount =
          new Uint32List.view(buffer, offset, header.particleTypeCount);
      offset += enteredCount.lengthInBytes;

      // Get sticked particle counting.
      final stickedCount =
          new Uint32List.view(buffer, offset, header.particleTypeCount);
      offset += stickedCount.lengthInBytes;

      list[i] = new Tuple2<Uint32List, Uint32List>(enteredCount, stickedCount);
    }
    return list;
  }

  /// Get list of membrane domains.
  /// TODO: check with multiple membranes (eliminate stride issues).
  List<Domain> generateMembraneDomains() {
    var list = new List<Domain>(header.membraneCount);
    var offset = header.membranesOffset;
    for (var i = 0; i < header.membraneCount; i++) {
      list[i] = new Domain.fromBuffer(buffer, offset);
      offset += list[i].sizeInBytes;
      offset += 6 * header.particleTypeCount;
    }
    return list;
  }
}

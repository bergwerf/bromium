// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

// Some shorthand consts for typed data byte count.
const _f32b = Float32List.BYTES_PER_ELEMENT;
const _i16b = Int16List.BYTES_PER_ELEMENT;
const _ui32b = Uint32List.BYTES_PER_ELEMENT;
const _ui16b = Uint16List.BYTES_PER_ELEMENT;
const _ui8b = Uint8List.BYTES_PER_ELEMENT;

/// Class for transferring and manipulating simulation data using only ByteData.
class SimulationBuffer {
  // Byte data packing offsets
  static const nMembraneDims = 6;
  static const nTypesOffset = 0;
  static const nParticlesOffset = 1;
  static const nMembranesOffset = 2;
  static const nInactiveOffset = 3;
  static const pTypeOffset = 4 * _ui32b;
  int pCoordsOffset, pColorOffset, memPOffset, memDimOffset, memDeltaOffset;

  /// Byte buffer that contains all data in this class.
  final ByteBuffer _buffer;

  /// Simulation dimension
  Uint32List dimensions;

  /// Particle type
  Int16List pType;

  /// Particle coordinates
  Uint16List pCoords;

  /// Particle color
  Uint8List pColor;

  /// Membrane in/outward permeability for each membrane and each particle.
  Float32List membranePermeability;

  /// Membrane domain dimensions
  ///
  /// Currenly all domains (box and ellipsoid) can be described using only
  /// 6 values (translation and scaling, we do not currenly support rotation).
  /// If more complex domains are added we will have to rethink this.
  Float32List membraneDimensions;

  /// Membrane domain delta values
  ///
  /// This array has the same limitation as [membraneDimensions].
  Float32List membraneDelta;

  /// Construct from ByteData.
  SimulationBuffer.fromByteBuffer(this._buffer) {
    // Create dimensions view.
    dimensions = new Uint32List.view(_buffer, 0, 4);

    // Create all views.
    pType = new Int16List.view(_buffer, pTypeOffset, nParticles);
    pCoordsOffset = pTypeOffset + pType.lengthInBytes;
    pCoords = new Uint16List.view(_buffer, pCoordsOffset, nParticles * 3);
    pColorOffset = pCoordsOffset + pCoords.lengthInBytes;
    pColor = new Uint8List.view(_buffer, pColorOffset, nParticles * 4);
    memPOffset = pColorOffset + pColor.lengthInBytes;
    membranePermeability =
        new Float32List.view(_buffer, memPOffset, nMembranes * 2 * nTypes);
    memDimOffset = memPOffset + membranePermeability.lengthInBytes;
    membraneDimensions =
        new Float32List.view(_buffer, memDimOffset, nMembranes * 6);
    memDeltaOffset = memDimOffset + membraneDimensions.lengthInBytes;
    membraneDelta =
        new Float32List.view(_buffer, memDeltaOffset, nMembranes * 6);
  }

  /// Construct empty data from dimensions.
  factory SimulationBuffer.fromDimensions(
      int nTypes, int nParticles, int nMembranes) {
    // Allocate byte data.
    var byteData = new ByteData(pTypeOffset +
        (nParticles * _i16b) +
        (nParticles * 3 * _ui16b) +
        (nParticles * 4 * _ui8b) +
        (nMembranes * 2 * nTypes + nMembranes * 12) * _f32b);

    // Load simulation dimensions.
    var dimensions = new Uint32List.view(byteData.buffer, 0, 4);
    dimensions[0] = nTypes;
    dimensions[1] = nParticles;
    dimensions[2] = nMembranes;

    // Create simulation buffer from this byte data.
    return new SimulationBuffer.fromByteBuffer(byteData.buffer);
  }

  /// Get the backend byte data.
  ByteBuffer get byteBuffer => _buffer;

  // Simulation dimension getters and setters
  int get nTypes => dimensions[nTypesOffset];
  int get nParticles => dimensions[nParticlesOffset];
  int get nMembranes => dimensions[nMembranesOffset];
  int get nInactive => dimensions[nInactiveOffset];
  set nInactive(int n) => dimensions[nInactiveOffset] = n;

  /// Compute index of the last active particle (before the tail of inactive
  /// particles).
  int get lastActiveParticleIdx => nParticles - 1 - nInactive;

  /// Compute index of the first inactive particle (front of the tail of
  /// inactive particles).
  int get firstInactiveParticleIdx => nParticles - nInactive;

  /// Compute the number of active particles.
  /// Alias for [firstInactiveParticleIdx].
  int get activeParticleCount => firstInactiveParticleIdx;

  /// Get the membrane inward permeability for the given particle type.
  double getInwardPermeability(int membrane, int type) {
    return membranePermeability[membrane * (nTypes * 2) + type * 2];
  }

  /// Get the membrane outward permeability for the given particle type.
  double getOutwardPermeability(int membrane, int type) {
    return membranePermeability[membrane * (nTypes * 2) + type * 2 + 1];
  }

  /// Set the membrane inward permeability for the given particle type.
  void setInwardPermeability(int membrane, int type, double value) {
    membranePermeability[membrane * (nTypes * 2) + type * 2] = value;
  }

  /// Set the membrane outward permeability for the given particle type.
  void setOutwardPermeability(int membrane, int type, double value) {
    membranePermeability[membrane * (nTypes * 2) + type * 2 + 1] = value;
  }

  /// Get membrane dimensions (array with nMembraneDims values).
  Float32List getMembraneDimensions(int membrane) {
    return new Float32List.view(_buffer,
        memDimOffset + membrane * nMembraneDims * _f32b, nMembraneDims);
  }

  /// Set membrane dimensions (array with nMembraneDims values).
  void setMembraneDimensions(int membrane, Float32List dims) {
    for (var i = 0; i < dims.length && i < nMembraneDims; i++) {
      membraneDimensions[membrane * nMembraneDims + i] = dims[i];
    }
  }
}

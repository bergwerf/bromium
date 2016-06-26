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
const _i8b = Uint8List.BYTES_PER_ELEMENT;

/// Class for transferring and manipulating simulation data using only ByteData.
class SimulationBuffer {
  // Byte data packing offsets
  static const nMembraneDims = 6;
  static const _nTypesOffset = 0;
  static const _nParticlesOffset = 1;
  static const _nMembranesOffset = 2;
  static const _nInactiveOffset = 3;
  static const _pTypeOffset = 4 * _ui32b;
  int _pCoordsOffset,
      _pColorOffset,
      _pMembranesOffset,
      _memParOffset,
      _memPerOffset,
      _memOldDimsOffset,
      _memNewDimsOffset;

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

  /// Particle parent membranes
  Int8List pMembranes;

  /// Number of particles in each membrane
  Uint32List membraneParticleCount;

  /// Membrane in/outward permeability for each membrane and each particle.
  Float32List membranePermeability;

  /// Old and new membrane dimensions
  ///
  /// Currenly all domains (box and ellipsoid) can be described using only
  /// 6 values (translation and scaling, we do not currenly support rotation).
  /// If more complex domains are added we will have to rethink this.
  Float32List membraneOldDims, membraneNewDims;

  /// Construct from ByteData.
  SimulationBuffer.fromByteBuffer(this._buffer) {
    // Create dimensions view.
    dimensions = new Uint32List.view(_buffer, 0, 4);

    // Create all views.
    pType = new Int16List.view(_buffer, _pTypeOffset, nParticles);

    _pCoordsOffset = _pTypeOffset + pType.lengthInBytes;
    pCoords = new Uint16List.view(_buffer, _pCoordsOffset, nParticles * 3);

    _pColorOffset = _pCoordsOffset + pCoords.lengthInBytes;
    pColor = new Uint8List.view(_buffer, _pColorOffset, nParticles * 4);

    _pMembranesOffset = _pColorOffset + pColor.lengthInBytes;
    pMembranes =
        new Int8List.view(_buffer, _pMembranesOffset, nParticles * nMembranes);

    _memParOffset = _pMembranesOffset + pMembranes.lengthInBytes;
    membraneParticleCount =
        new Uint32List.view(_buffer, _memParOffset, nMembranes * nTypes);

    _memPerOffset = _memParOffset + membraneParticleCount.lengthInBytes;
    membranePermeability =
        new Float32List.view(_buffer, _memPerOffset, nMembranes * 2 * nTypes);

    _memOldDimsOffset = _memPerOffset + membranePermeability.lengthInBytes;
    membraneOldDims =
        new Float32List.view(_buffer, _memOldDimsOffset, nMembranes * 6);

    _memNewDimsOffset = _memOldDimsOffset + membraneOldDims.lengthInBytes;
    membraneNewDims =
        new Float32List.view(_buffer, _memNewDimsOffset, nMembranes * 6);
  }

  /// Construct empty data from dimensions.
  factory SimulationBuffer.fromDimensions(
      int nTypes, int nParticles, int nMembranes, int nInactive) {
    // Allocate byte data.
    var byteData = new ByteData(_pTypeOffset +
        // Particle type
        (nParticles * _i16b) +
        // Particle coords
        (nParticles * 3 * _ui16b) +
        // Particle colors
        (nParticles * 4 * _ui8b) +
        // Particle membranes
        (nParticles * nMembranes * _i8b) +
        // Membrane particle count
        (nMembranes * nTypes * _ui32b) +
        // Membrane permeability and membrane dimensions (old + new)
        (nMembranes * 2 * nTypes + nMembranes * 12) * _f32b);

    // Load simulation dimensions.
    var dimensions = new Uint32List.view(byteData.buffer, 0, 4);
    dimensions[0] = nTypes;
    dimensions[1] = nParticles;
    dimensions[2] = nMembranes;
    dimensions[3] = nInactive;

    // Create simulation buffer from this byte data.
    return new SimulationBuffer.fromByteBuffer(byteData.buffer);
  }

  /// Get the backend byte data.
  ByteBuffer get byteBuffer => _buffer;

  // Simulation dimension getters and setters
  int get nTypes => dimensions[_nTypesOffset];
  int get nParticles => dimensions[_nParticlesOffset];
  int get nMembranes => dimensions[_nMembranesOffset];
  int get nInactive => dimensions[_nInactiveOffset];
  set nInactive(int n) => dimensions[_nInactiveOffset] = n;

  /// Compute index of the last active particle (before the tail of inactive
  /// particles).
  int get lastActiveParticleIdx => nParticles - 1 - nInactive;

  /// Compute index of the first inactive particle (front of the tail of
  /// inactive particles).
  int get firstInactiveParticleIdx => nParticles - nInactive;

  /// Compute the number of active particles.
  /// Alias for [firstInactiveParticleIdx].
  int get activeParticleCount => firstInactiveParticleIdx;

  /// Get particle coordinates as vector.
  Vector3 getParticleVec(int p) {
    return new Vector3(pCoords[p * 3].toDouble(), pCoords[p * 3 + 1].toDouble(),
        pCoords[p * 3 + 2].toDouble());
  }

  /// Set particle coordinates.
  void setParticleCoords(int p, Vector3 point) {
    for (var d = 0; d < 3; d++) {
      pCoords[p * 3 + d] = point[d].round();
    }
  }

  /// Set particle color.
  void setParticleColor(int p, List<int> color) {
    for (var c = 0; c < 4; c++) {
      pColor[p * 4 + c] = color[c];
    }
  }

  /// Check if the given particle [i] is inside the given membrane [m].
  bool isInMembrane(int i, int m) {
    return pMembranes[i * nMembranes + m] == 1;
  }

  /// Set the given particle [i] to be inside the given membrane [m].
  void setParentMembrane(int i, int m) {
    pMembranes[i * nMembranes + m] = 1;
    membraneParticleCount[m * nTypes + pType[i]]++;
  }

  /// Unset the given particle [i] to be inside the given membrane [m].
  void unsetParentMembrane(int i, int m) {
    pMembranes[i * nMembranes + m] = 0;
    membraneParticleCount[m * nTypes + pType[i]]--;
  }

  /// Check if the parent membranes of the two given particles are equal.
  bool matchParentMembranes(int a, int b) {
    for (var m = 0; m < nMembranes; m++) {
      if (isInMembrane(a, m) != isInMembrane(b, m)) {
        return false;
      }
    }
    return true;
  }

  /// Return the number of particles of a specific type in the given membrane.
  int particleCountIn(int type, int membrane) {
    return membraneParticleCount[membrane * nTypes + type];
  }

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

  /// Randomly decide if the given particle can move into the given membrane.
  bool rndInwardPermeability(int p, int m) {
    return new Random().nextDouble() < getInwardPermeability(m, pType[p]);
  }

  /// Randomly decide if the given particle can move out of the given membrane.
  bool rndOutwardPermeability(int p, int m) {
    return new Random().nextDouble() < getOutwardPermeability(m, pType[p]);
  }

  /// Set membrane dimensions (array with length nMembraneDims).
  void setMembraneDims(int membrane, Float32List dims, [bool both = false]) {
    for (var i = 0; i < nMembraneDims; i++) {
      if (both) {
        membraneOldDims[membrane * nMembraneDims + i] = dims[i];
      }
      membraneNewDims[membrane * nMembraneDims + i] = dims[i];
    }
  }

  /// Get membrane dimensions (array with nMembraneDims values).
  Float32List getMembraneDims(int membrane, [bool newDims = false]) {
    var dims = new Float32List(nMembraneDims);
    for (var i = 0; i < nMembraneDims; i++) {
      dims[i] = newDims
          ? membraneNewDims[membrane * nMembraneDims + i]
          : membraneOldDims[membrane * nMembraneDims + i];
    }
    return dims;
  }

  /// Check if the dimensions of the given membrane have changed.
  bool membraneDimsChanged(int m) {
    for (var i = 0; i < nMembraneDims; i++) {
      if (membraneOldDims[m * nMembraneDims + i] !=
          membraneNewDims[m * nMembraneDims + i]) {
        return true;
      }
    }
    return false;
  }

  /// Copy the the new membrane dimensions into the old ones for membrane [m].
  void applyMembraneMotion(int m) {
    for (var i = 0; i < nMembraneDims; i++) {
      membraneOldDims[m * nMembraneDims + i] =
          membraneNewDims[m * nMembraneDims + i];
    }
  }
}

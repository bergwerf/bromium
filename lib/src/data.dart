// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Separate class for all data that is kept during each simulation.
class BromiumEngineData {
  /// Type index of each particle
  Uint16List particleType;

  /// Position of each particle as a WebGL buffer
  Float32List particlePosition;

  /// Color of each particle as a WebGL buffer
  Float32List particleColor;

  /// Particle information
  Map<String, ParticleInfo> particles = new Map<String, ParticleInfo>();

  /// Particle label index
  List<String> particleLabels = new List<String>();
}

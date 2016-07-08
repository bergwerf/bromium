// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Particle type information
///
/// Particle type information is not included in the binary stream.
class ParticleType {
  /// Particle color
  final Vector3 color;

  /// Random walk step radius
  final double stepRadius;

  ParticleType(Vector4 color, this.stepRadius) : color = color.rgb;
}

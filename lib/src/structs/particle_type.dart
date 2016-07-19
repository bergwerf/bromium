// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Particle type information
///
/// Particle type information is not included in the binary stream.
class ParticleType {
  /// Display color
  final Vector3 displayColor;

  /// Random walk speed
  final double speed;

  /// Particle radius
  final double radius;

  ParticleType(Vector4 color, this.speed, this.radius)
      : displayColor = color.rgb;
}

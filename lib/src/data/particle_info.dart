// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Information of one particle in [ParticleDict]
class ParticleInfo {
  /// Random walk step radius
  final double rndWalkStepR;

  /// Random walk integer step parameters
  final int rndWalkOdd, rndWalkSub;

  /// Sub particles by their index.
  final List<int> subParticles;

  /// Particle color
  final List<int> rgba;

  /// Constructor
  ParticleInfo(this.subParticles, double r, RgbColor color)
      : rndWalkStepR = r,
        rndWalkOdd = r.ceil() * 2 + 1,
        rndWalkSub = r.ceil(),
        rgba = [color.r, color.g, color.b, 255];
}

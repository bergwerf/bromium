// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// A particle domain for the BromiumEngine
abstract class Domain {
  /// Compute a random point within the domain.
  Vector3 computeRandomPoint(Random rng);

  /// Generate a GL_TRIANGLES polygon outlining this domain.
  Float32List computePolygon();

  /// Check if the given point is contained in this domain.
  bool contains(Vector3 point);

  /// Check if the given ray intersects with the domain surface.
  bool surfaceIntersection(Ray ray);
}

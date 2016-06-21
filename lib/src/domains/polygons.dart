// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Compute list of triangles that make up the given domain.
Float32List computeDomainPolygon(DomainType type, Float32List dims) {
  return new Domain.fromType(type, dims).computePolygon();
}

/// Compute list of lines that form a wireframe for the given domain.
Float32List computeDomainWireframe(DomainType type, Float32List dims) {
  return new Domain.fromType(type, dims).computeWireframe();
}

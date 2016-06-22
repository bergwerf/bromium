// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Rectangular cuboid domain
class BoxDomain extends Domain {
  /// Small corner
  Vector3 sc;

  /// Large corner
  Vector3 lc;

  /// Constuctor
  BoxDomain(this.sc, this.lc) : super(DomainType.box) {
    // Do a sanity check.
    if (sc.x > lc.x) {
      var scx = sc.x;
      sc.x = lc.x;
      lc.x = scx;
    }
    if (sc.y > lc.y) {
      var scy = sc.y;
      sc.y = lc.y;
      lc.y = scy;
    }
    if (sc.z > lc.z) {
      var scz = sc.z;
      sc.z = lc.z;
      lc.z = scz;
    }
  }

  /// Construct from dimensions array.
  factory BoxDomain.fromDims(Float32List dims) {
    return new BoxDomain(new Vector3.array(dims), new Vector3.array(dims, 3));
  }

  /// Get dimensions.
  Float32List getDims() =>
      new Float32List.fromList([sc.x, sc.y, sc.z, lc.x, lc.y, lc.z]);

  /// The bounding box is the same as this.
  BoxDomain computeBoundingBox() => this;

  /// Random distribution is guaranteed since the coordinate system is not
  /// deformed.
  Vector3 computeRandomPoint(Random rng) {
    var ret = new Vector3.zero();
    ret.x = this.sc.x + rng.nextDouble() * (this.lc.x - this.sc.x);
    ret.y = this.sc.y + rng.nextDouble() * (this.lc.y - this.sc.y);
    ret.z = this.sc.z + rng.nextDouble() * (this.lc.z - this.sc.z);
    return ret;
  }

  /// Check if the given coordinates are contained in this box.
  bool contains(num x, num y, num z) {
    return !(x < sc.x ||
        x > lc.x ||
        y < sc.y ||
        y > lc.y ||
        z < sc.z ||
        z > lc.z);
  }

  /// Algorithm to compute a list of lines that make up a box wireframe.
  Float32List computeWireframe() {
    var vertices = new Float32List((4 + 4 * 4) * 2 * 3);

    // Add top and bottom quad.
    for (var f = 0; f < 2; f++) {
      for (var i = 0; i < 4; i++) {
        var offset = f * 24 + i * 6;
        bool a = i < 2, b = i == 1 || i == 2;
        vertices[offset + 0] = a ? sc.x : lc.x;
        vertices[offset + 1] = b ? lc.y : sc.y;
        vertices[offset + 2] = f == 0 ? sc.z : lc.z;
        vertices[offset + 3] = b ? lc.x : sc.x;
        vertices[offset + 4] = a ? lc.y : sc.y;
        vertices[offset + 5] = f == 0 ? sc.z : lc.z;
      }
    }

    // Add connecting lines.
    for (var i = 0; i < 4; i++) {
      var offset = 48 + i * 6;
      vertices[offset + 0] = i < 2 ? sc.x : lc.x;
      vertices[offset + 1] = i > 0 && i < 3 ? lc.y : sc.y;
      vertices[offset + 2] = sc.z;
      vertices[offset + 3] = i < 2 ? sc.x : lc.x;
      vertices[offset + 4] = i > 0 && i < 3 ? lc.y : sc.y;
      vertices[offset + 5] = lc.z;
    }

    return vertices;
  }

  /// Extra fancy algorithm to compute all triangles that make up a box.
  Float32List computePolygon() {
    var vertices = new Float32List(3 * 3 * 2 * 2 * 3);
    var c = [sc.x, sc.y, sc.z, lc.x, lc.y, lc.z]; // corners

    /// Super fancy algorithm for generating triangles of boxs.
    ///
    /// Variables:
    /// `a`: axis (x, y, z)
    /// `f`: face (front, back)
    /// `t`: triangle (first, second):
    /// `v`: triangle vertex (1, 2, 3)

    for (var a = 0; a < 3; a++) {
      // An axis has 18 * 2 = 36 floats.
      for (var f = 0; f < 2; f++) {
        // A face has 9 * 2 = 18 floats.
        for (var t = 0; t < 2; t++) {
          // A triangle has 3 * 3 = 9 floats.
          for (var v = 0; v < 3; v++) {
            // A vertex has 3 floats.

            /// We want to produce the second row from the first row:
            ///
            ///     t v | c1 c2 | c1 = (t + v) % 2 | c2 = (t + v - c1) / 2
            ///     0 0 | 0  0  | 0                | 0
            ///     0 1 | 1  0  | 1                | 0
            ///     0 2 | 0  1  | 0                | 1
            ///     1 0 | 1  0  | 1                | 0
            ///     1 1 | 0  1  | 0                | 1
            ///     1 2 | 1  1  | 1                | 1

            // Compute vextex offset.
            // Note: the vertex order in the triangle is reversed when
            // t + f != 1, this is a dirty trick to fix face culling in OpenGL.
            var offset =
                a * 36 + f * 18 + t * 9 + (t + f == 1 ? v * 3 : 6 - v * 3);

            // Compute offset of variable dimensions.
            // This will give access to the two free dimensions. e.g. if
            // the axis is the y axis then y is defined for this face but
            // x and z are free (their value is determined by `c1` and `c2`)
            // so a = 1, o1 = 2 (z) and o2 = 0 (x)
            var o1 = (a + 1) % 3, o2 = (a + 2) % 3;

            // Compute corner offset (mix small and large corners).
            var c1 = ((t + v) % 2).toInt(), c2 = (t + v - c1) ~/ 2;

            vertices[offset + a] = c[f * 3 + a];
            vertices[offset + o1] = c[c1 * 3 + o1];
            vertices[offset + o2] = c[c2 * 3 + o2];
          }
        }
      }
    }
    return vertices;
  }
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Generate AABB wireframe.
List<Vector3> generateAabbWireframe(Aabb3 aabb) {
  var vertices = new List<Vector3>((4 + 2 * 4) * 2);

  // Add top and bottom quad.
  for (var f = 0; f < 2; f++) {
    for (var i = 0; i < 4; i++) {
      var offset = f * 8 + i * 2;
      bool a = i < 2, b = i == 1 || i == 2;
      vertices[offset + 0] = new Vector3(a ? aabb.min.x : aabb.max.x,
          b ? aabb.max.y : aabb.min.y, f == 0 ? aabb.min.z : aabb.max.z);
      vertices[offset + 1] = new Vector3(b ? aabb.max.x : aabb.min.x,
          a ? aabb.max.y : aabb.min.y, f == 0 ? aabb.min.z : aabb.max.z);
    }
  }

  // Add connecting lines between the top and bottom face.
  for (var i = 0; i < 4; i++) {
    var offset = 16 + i * 2;
    vertices[offset + 0] = new Vector3(i < 2 ? aabb.min.x : aabb.max.x,
        i > 0 && i < 3 ? aabb.max.y : aabb.min.y, aabb.min.z);
    vertices[offset + 1] = new Vector3(i < 2 ? aabb.min.x : aabb.max.x,
        i > 0 && i < 3 ? aabb.max.y : aabb.min.y, aabb.max.z);
  }

  return vertices;
}

/// Generate AABB polygon mesh.
List<Vector3> generateAabbPolygonMesh(Aabb3 aabb) {
  var vertices = new List<Vector3>(3 * 3 * 2 * 2);
  var dims = [
    aabb.min.x,
    aabb.min.y,
    aabb.min.z,
    aabb.max.x,
    aabb.max.y,
    aabb.max.z
  ];

  /// Variables:
  /// `a`: axis (x, y, z)
  /// `f`: face (front, back)
  /// `t`: triangle (first, second):
  /// `v`: triangle vertex (1, 2, 3)

  for (var a = 0; a < 3; a++) {
    // An axis has 6 * 2 = 12 vertices.
    for (var f = 0; f < 2; f++) {
      // A face has 3 * 2 = 6 vertices.
      for (var t = 0; t < 2; t++) {
        // A triangle has 3 vertices.
        for (var v = 0; v < 3; v++) {
          /// We want to produce the second row from the first row:
          ///
          ///     t v | c1 c2 | c1 = (t + v) % 2 | c2 = (t + v - c1) / 2
          ///     0 0 | 0  0  | 0                | 0
          ///     0 1 | 1  0  | 1                | 0
          ///     0 2 | 0  1  | 0                | 1
          ///     1 0 | 1  0  | 1                | 0
          ///     1 1 | 0  1  | 0                | 1
          ///     1 2 | 1  1  | 1                | 1

          // Compute vertex offset.
          // Note: the vertex order in the triangle is reversed when
          // t + f != 1, this is a dirty trick to fix face culling in OpenGL.
          var offset = a * 12 + f * 6 + t * 3 + (t + f != 1 ? v : 3 - v);

          // Compute offset of variable dimensions.
          // This will give access to the two free dimensions. e.g. if
          // the axis is the y axis then y is defined for this face but
          // x and z are free (their value is determined by `c1` and `c2`)
          // so a = 1, o1 = 2 (z) and o2 = 0 (x)
          var o1 = (a + 1) % 3, o2 = (a + 2) % 3;

          // Compute corner offset (mix small and large corners).
          var c1 = ((t + v) % 2).toInt(), c2 = (t + v - c1) ~/ 2;

          var array = new List<double>(3);
          array[a] = dims[f * 3 + a];
          array[o1] = dims[c1 * 3 + o1];
          array[o2] = dims[c2 * 3 + o2];
          vertices[offset] = new Vector3.array(array);
        }
      }
    }
  }

  return vertices;
}

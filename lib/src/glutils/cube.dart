// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.glutils;

class GlCube extends GlGeometry {
  factory GlCube(gl.RenderingContext ctx,
      {GlShader shader: null,
      GlShader wireframeShader: null,
      GlShader surfaceShader: null,
      Vector4 wireframeColor: null,
      Vector4 surfaceColor: null}) {
    return new GlCube._create(
        new GlObject.from(
            ctx,
            wireframeShader != null ? wireframeShader : shader,
            cubePositions,
            new Vector4List.fromList(
                new List<Vector4>.filled(cubePositions.length, wireframeColor)),
            wireframeIndices),
        new GlObject.from(
            ctx,
            surfaceShader != null ? surfaceShader : shader,
            cubePositions,
            new Vector4List.fromList(
                new List<Vector4>.filled(cubePositions.length, surfaceColor)),
            surfaceIndices));
  }

  /// Internal constuctor
  GlCube._create(GlObject wireframe, GlObject surface)
      : super(wireframe, surface);

  /// Compute transformation to transform the standard cube into the given AABB.
  static Matrix4 computeTransform(Aabb3 aabb) {
    var mat = new Matrix4.identity();
    mat.scale(aabb.max.x - aabb.min.x, aabb.max.y - aabb.min.y,
        aabb.max.z - aabb.min.z);
    mat.translate(aabb.min.x, aabb.min.y, aabb.min.z);
    return mat;
  }

  /// Cube positions
  static Vector3List cubePositions = new Vector3List.fromList([
    new Vector3(0.0, 0.0, 0.0),
    new Vector3(0.0, 1.0, 0.0),
    new Vector3(1.0, 1.0, 0.0),
    new Vector3(1.0, 0.0, 0.0),
    new Vector3(0.0, 0.0, 1.0),
    new Vector3(0.0, 1.0, 1.0),
    new Vector3(1.0, 1.0, 1.0),
    new Vector3(1.0, 0.0, 1.0)
  ]);

  /// Wireframe indices
  static Uint16List wireframeIndices = new Uint16List.fromList([
    // Back
    0, 1, 1, 2, 2, 3, 3, 0,
    // Front
    4, 5, 5, 6, 6, 7, 7, 4,
    // Middle
    0, 4, 1, 5, 2, 6, 3, 7
  ]);

  /// Surface indices
  static Uint16List surfaceIndices = new Uint16List.fromList([
    // Back
    0, 2, 1, 0, 3, 2,
    // Front
    4, 5, 6, 4, 6, 7,

    // Sides
    0, 1, 5, 0, 5, 4,
    //
    1, 2, 6, 1, 6, 5,
    //
    2, 3, 7, 2, 7, 6,
    //
    3, 0, 4, 3, 4, 7
  ]);
}

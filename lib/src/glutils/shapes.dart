// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.glutils;

/// Base for drawing shapes
class GlShape {
  /// Wireframe and polygon mesh objects.
  final GlObject wireframe, surface;

  /// Number of vertices
  final int _vertexCount;

  GlShape(this.wireframe, this.surface, this._vertexCount);

  /// Set the transformation of [wireframe] and [surface] at once.
  set transform(Matrix4 matrix) {
    wireframe.transform = matrix;
    surface.transform = matrix;
  }

  /// Draw the shape.
  void draw({bool drawWireframe: true, bool drawSurface: true}) {
    if (drawWireframe) {
      wireframe.drawElements(gl.LINES, _vertexCount);
    }
    if (drawSurface) {
      wireframe.drawElements(gl.TRIANGLES, (_vertexCount / 3).truncate());
    }
  }
}

class GlCube extends GlShape {
  factory GlCube(gl.RenderingContext ctx, Vector4 color,
      {GlShader shader: null,
      GlShader wireframeShader: null,
      GlShader surfaceShader: null}) {
    var cubeMesh = new CubeGenerator().createCube(1, 1, 1);
    var cubePositions = cubeMesh.getViewForAttrib('POSITION');
    var cubeColors = new Vector4List.fromList(
        new List<Vector4>.filled(cubePositions.length, color));

    return new GlCube._create(
        new GlObject.from(
            ctx,
            wireframeShader != null ? wireframeShader : shader,
            cubePositions,
            cubeColors,
            generateWireframeIndices()),
        new GlObject.from(ctx, surfaceShader != null ? surfaceShader : shader,
            cubePositions, cubeColors, cubeMesh.indices),
        cubePositions.length);
  }

  /// Internal constuctor
  GlCube._create(GlObject wireframe, GlObject surface, int vertexCount)
      : super(wireframe, surface, vertexCount);

  /// Generate element indices for the wireframe object. This function is
  /// missing from `vector_math`.
  static Uint16List generateWireframeIndices() {
    return new Uint16List.fromList([
      // Front
      0, 1, 1, 2, 2, 3, 3, 0,
      // Back
      20, 21, 21, 22, 22, 23, 23, 20,
      // Middle
      0, 20, 1, 21, 2, 22, 3, 23
    ]);
  }
}

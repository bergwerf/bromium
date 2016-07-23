// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.glutils;

class GlSphere extends GlGeometry {
  factory GlSphere(gl.RenderingContext ctx, int phiSegments, int thetaSegments,
      {GlShader shader: null,
      GlShader wireframeShader: null,
      GlShader surfaceShader: null,
      Vector4 wireframeColor: null,
      Vector4 surfaceColor: null}) {
    var positions = generateSpherePositions(phiSegments, thetaSegments);
    return new GlSphere._create(
        new GlObject.from(
            ctx,
            wireframeShader != null ? wireframeShader : shader,
            positions,
            new Vector4List.fromList(
                new List<Vector4>.filled(positions.length, wireframeColor)),
            generateWireframeIndices(phiSegments, thetaSegments)),
        new GlObject.from(
            ctx,
            surfaceShader != null ? surfaceShader : shader,
            positions,
            new Vector4List.fromList(
                new List<Vector4>.filled(positions.length, surfaceColor)),
            generateSurfaceIndices(phiSegments, thetaSegments)));
  }

  /// Internal constuctor
  GlSphere._create(GlObject wireframe, GlObject surface)
      : super(wireframe, surface);

  /// Compute transformation to transform the standard sphere into the given
  /// ellipsoid.
  static Matrix4 computeTransform(Vector3 center, Vector3 semiAxes) {
    var mat = new Matrix4.identity();
    mat.translate(center.x, center.y, center.z);
    mat.scale(semiAxes.x, semiAxes.y, semiAxes.z);
    return mat;
  }

  /// Cube positions
  static Vector3List generateSpherePositions(
      int phiSegments, int thetaSegments) {
    var v = new Vector3List((phiSegments - 1) * thetaSegments + 2);

    // Add top and bottom.
    v[0] = new Vector3(.0, .0, 1.0);
    v[1] = new Vector3(.0, .0, -1.0);
    var i = 2;

    for (var phi = 1; phi < phiSegments; phi++) {
      var p = PI / phiSegments * phi;
      for (var theta = 0; theta < thetaSegments; theta++) {
        var t = 2 * PI / thetaSegments * theta;
        v[i++] = new Vector3(sin(p) * cos(t), sin(p) * sin(t), cos(p));
      }
    }

    return v;
  }

  /// Wireframe indices
  static Uint16List generateWireframeIndices(
      int phiSegments, int thetaSegments) {
    var l = new Uint16List(
        (phiSegments - 1) * thetaSegments * 4 + thetaSegments * 2);
    var i = 0;

    // (phiSegments - 1) * thetaSegments * 4
    for (var phi = 1; phi < phiSegments; phi++) {
      for (var theta = 0; theta < thetaSegments; theta++) {
        var idx = 2 + (phi - 1) * thetaSegments + theta;

        if (phi == 1) {
          l[i++] = 0;
          l[i++] = idx;
        } else {
          l[i++] = idx - thetaSegments;
          l[i++] = idx;
        }

        if (theta == 0) {
          l[i++] = idx + thetaSegments - 1;
          l[i++] = idx;
        } else {
          l[i++] = idx - 1;
          l[i++] = idx;
        }
      }
    }

    // Bottom triangle fan (thetaSegments * 2)
    for (var theta = 0; theta < thetaSegments; theta++) {
      l[i++] = 1;
      l[i++] = 2 + (phiSegments - 2) * thetaSegments + theta;
    }

    return l;
  }

  /// Surface indices
  static Uint16List generateSurfaceIndices(int phiSegments, int thetaSegments) {
    var t = new Uint16List((phiSegments - 1) * thetaSegments * 6);
    var i = 0;

    // (phiSegments - 1) * thetaSegments * 4
    for (var phi = 1; phi < phiSegments; phi++) {
      for (var theta = 0; theta < thetaSegments; theta++) {
        var idx = 2 + (phi - 1) * thetaSegments + theta;
        var prev = theta == 0 ? idx + thetaSegments - 1 : idx - 1;
        var up = phi == 1 ? 0 : idx - thetaSegments;
        var down = phi == phiSegments - 1 ? 1 : prev + thetaSegments;

        // Note that sine and cosine move counter clockwise.
        t[i++] = idx;
        t[i++] = prev;
        t[i++] = up;
        t[i++] = idx;
        t[i++] = down;
        t[i++] = prev;
      }
    }

    return t;
  }
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Generate x, y, and z axis ellipses.
Vector3List generateEllipsoidWireframe(EllipsoidDomain e, int detail) {
  var v = new Vector3List(3 * detail * 2);

  for (var axis = 0, i = 0; axis < 3; axis++) {
    // Compute sine translation to implicitly use cosine for the right axes.
    var xtrans = axis == 1 ? PI / 2 : 0;
    var ytrans = axis == 2 ? PI / 2 : 0;
    var ztrans = axis == 0 ? PI / 2 : 0;

    // Add line by line.
    for (var thetaI = 0; thetaI < detail; thetaI++, i += 2) {
      var theta = [thetaI * 2 * PI / detail, (thetaI + 1) * 2 * PI / detail];

      for (var vertex = 0; vertex < 2; vertex++) {
        v[i + vertex] = e.center + e.semiAxes.clone()
          ..multiply(new Vector3(
              axis == 0 ? 0 : sin(theta[vertex] + xtrans),
              axis == 1 ? 0 : sin(theta[vertex] + ytrans),
              axis == 2 ? 0 : sin(theta[vertex] + ztrans)));
      }
    }
  }

  return v;
}

/// Generate triangles that cover the surface of this ellipsoid.
Vector3List generateEllipsoidPolygonMesh(
    EllipsoidDomain e, int thetaDetail, int phiDetail) {
  var v = new Vector3List(thetaDetail * phiDetail * 6);

  for (var thetaI = 0, i = 0; thetaI < thetaDetail; thetaI++) {
    for (var phiI = 0; phiI < phiDetail; phiI++, i += 6) {
      var theta = [
        thetaI * 2 * PI / thetaDetail,
        (thetaI + 1) * 2 * PI / thetaDetail
      ];
      var phi = [phiI * PI / phiDetail, (phiI + 1) * PI / phiDetail];

      // The computed theta and phi describe a quad on the surface of the
      // ellipsoid. First we compute the actual quad vertices.
      var v1 = e.center + e.semiAxes.clone()
        ..multiply(new Vector3(sin(theta[0]) * cos(phi[0]),
            sin(theta[0]) * sin(phi[0]), cos(phi[0])));
      var v2 = e.center + e.semiAxes.clone()
        ..multiply(new Vector3(sin(theta[1]) * cos(phi[0]),
            sin(theta[1]) * sin(phi[0]), cos(phi[0])));
      var v3 = e.center + e.semiAxes.clone()
        ..multiply(new Vector3(sin(theta[1]) * cos(phi[1]),
            sin(theta[1]) * sin(phi[1]), cos(phi[1])));
      var v4 = e.center + e.semiAxes.clone()
        ..multiply(new Vector3(sin(theta[0]) * cos(phi[1]),
            sin(theta[0]) * sin(phi[1]), cos(phi[1])));

      // Link vertices to vertex array.
      v[i + 0] = v1;
      v[i + 1] = v2;
      v[i + 2] = v3;
      v[i + 3] = v1;
      v[i + 4] = v3;
      v[i + 5] = v4;
    }
  }

  return v;
}

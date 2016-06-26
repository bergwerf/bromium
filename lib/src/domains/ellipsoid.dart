// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Ellipsoid domain
class EllipsoidDomain extends Domain {
  /// Center
  Vector3 center;

  /// Semi-axis size
  double a, b, c;

  /// Constuctor
  EllipsoidDomain(this.center, this.a, this.b, this.c)
      : super(DomainType.ellipsoid);

  /// Construct from dimensions array.
  factory EllipsoidDomain.fromDims(Float32List dims) {
    return new EllipsoidDomain(
        new Vector3.array(dims), dims[3], dims[4], dims[5]);
  }

  /// Get dimensions.
  Float32List getDims() =>
      new Float32List.fromList([center.x, center.y, center.z, a, b, c]);

  /// Compute bounding box.
  BoxDomain computeBoundingBox() {
    var r = new Vector3(a, b, c);
    return new BoxDomain(center - r, center + r);
  }

  /// Check if the given coordinates are contained in this ellipsoid.
  bool _contains(num x, num y, num z) {
    x -= center.x;
    y -= center.y;
    z -= center.z;
    return (x * x) / (a * a) + (y * y) / (b * b) + (z * z) / (c * c) <= 1;
  }

  /// Return x, y, and z axis ellipses.
  Float32List computeWireframe() {
    var detail = 100;
    var v = new Float32List(3 * detail * 2 * 3);
    for (var ax = 0, i = 0; ax < 3; ax++) {
      var xtri = ax == 1 ? PI / 2 : 0;
      var ytri = ax == 2 ? PI / 2 : 0;
      var ztri = ax == 0 ? PI / 2 : 0;
      for (var _theta = 0; _theta < detail; _theta++, i += 6) {
        var th = [_theta * 2 * PI / detail, (_theta + 1) * 2 * PI / detail];
        for (var p = 0; p < 2; p++) {
          v[i + p * 3 + 0] = center.x + (ax == 0 ? 0 : a * sin(th[p] + xtri));
          v[i + p * 3 + 1] = center.y + (ax == 1 ? 0 : b * sin(th[p] + ytri));
          v[i + p * 3 + 2] = center.z + (ax == 2 ? 0 : c * sin(th[p] + ztri));
        }
      }
    }
    return v;
  }

  /// Return triangles that cover the surface of this ellipsoid.
  Float32List computePolygon() {
    var uDetail = 50, vDetail = 25;
    var vertices = new Float32List(uDetail * vDetail * 2 * 3 * 3);
    for (var _theta = 0, i = 0; _theta < uDetail; _theta++) {
      for (var _phi = 0; _phi < vDetail; _phi++, i += 2 * 3 * 3) {
        var u = [_theta * 2 * PI / uDetail, (_theta + 1) * 2 * PI / uDetail];
        var v = [_phi * PI / vDetail, (_phi + 1) * PI / vDetail];

        var v1 = new Vector3(a * cos(u[0]) * sin(v[0]),
                b * sin(u[0]) * sin(v[0]), c * cos(v[0])) +
            center;
        var v2 = new Vector3(a * cos(u[1]) * sin(v[0]),
                b * sin(u[1]) * sin(v[0]), c * cos(v[0])) +
            center;
        var v3 = new Vector3(a * cos(u[1]) * sin(v[1]),
                b * sin(u[1]) * sin(v[1]), c * cos(v[1])) +
            center;
        var v4 = new Vector3(a * cos(u[0]) * sin(v[1]),
                b * sin(u[0]) * sin(v[1]), c * cos(v[1])) +
            center;

        v1.copyIntoArray(vertices, i);
        v2.copyIntoArray(vertices, i + 3);
        v3.copyIntoArray(vertices, i + 6);
        v1.copyIntoArray(vertices, i + 9);
        v3.copyIntoArray(vertices, i + 12);
        v4.copyIntoArray(vertices, i + 15);
      }
    }
    return vertices;
  }
}

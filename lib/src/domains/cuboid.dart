// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Cuboid domain
class CuboidDomain implements Domain {
  /// Small corner
  Vector3 sc;

  /// Large corner
  Vector3 lc;

  /// Constuctor
  CuboidDomain(this.sc, this.lc) {
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

  Vector3 computeRandomPoint(Random rng) {
    var ret = new Vector3.zero();
    ret.x = this.sc.x + rng.nextDouble() * (this.lc.x - this.sc.x);
    ret.y = this.sc.y + rng.nextDouble() * (this.lc.y - this.sc.y);
    ret.z = this.sc.z + rng.nextDouble() * (this.lc.z - this.sc.z);
    return ret;
  }

  Float32List computePolygon() {
    //return new Float32List.fromList([]);
  }

  bool contains(Vector3 point) {}

  bool surfaceIntersection(Ray ray) {}
}

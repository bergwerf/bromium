// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// A particle domain for the BromiumEngine
// IGNORE: one_member_abstracts
abstract class Domain {
  Vector3 computeRandomPoint(Random rng);
}

class BoxDomain extends Domain {
  Vector3 smallCorner, largeCorner;

  // TODO: sanity check.
  BoxDomain(this.smallCorner, this.largeCorner);

  Vector3 computeRandomPoint(Random rng) {
    var ret = new Vector3.zero();
    ret.x = this.smallCorner.x +
        rng.nextDouble() * (this.largeCorner.x - this.smallCorner.x);
    ret.y = this.smallCorner.y +
        rng.nextDouble() * (this.largeCorner.y - this.smallCorner.y);
    ret.z = this.smallCorner.z +
        rng.nextDouble() * (this.largeCorner.z - this.smallCorner.z);
    return ret;
  }
}

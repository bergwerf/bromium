// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// This function applies one cycle of random motion to the given [BromiumData].
void _computeMotion(BromiumData data) {
  // IDEA: membrane collision computation might be faster by building a kind of
  // tree data structure (i.e. do not iterate through all particles each time
  // you compute a collision).

  var rng = new Random();
  OUTER: for (var i = 0; i < data.particleType.length; i++) {
    // If the particleType is -1 the particle is inactive.
    var type = data.particleType[i];
    if (type != -1) {
      // Compute random displacement.
      var motionX = rng.nextInt(data.randomWalkStep[type].oddSize) -
          data.randomWalkStep[type].sub;
      var motionY = rng.nextInt(data.randomWalkStep[type].oddSize) -
          data.randomWalkStep[type].sub;
      var motionZ = rng.nextInt(data.randomWalkStep[type].oddSize) -
          data.randomWalkStep[type].sub;

      // Correct displacement by processing it with every membrane.
      for (var m = 0; m < data.membranes.length; m++) {
        if (data.membranes[m].blockParticleMotion(
            type,
            data.particlePosition[i * 3 + 0],
            data.particlePosition[i * 3 + 1],
            data.particlePosition[i * 3 + 2],
            data.particlePosition[i * 3 + 0] + motionX,
            data.particlePosition[i * 3 + 1] + motionY,
            data.particlePosition[i * 3 + 2] + motionZ)) {
          continue OUTER;
        }
      }

      // No block; apply the motion.
      data.particlePosition[i * 3 + 0] += motionX;
      data.particlePosition[i * 3 + 1] += motionY;
      data.particlePosition[i * 3 + 2] += motionZ;
    }
  }
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// This function applies one cycle of random motion to the given [BromiumData].
void _computeMotion(BromiumData data) {
  var rng = new Random();
  OUTER: for (var i = 0; i < data.particleType.length; i++) {
    // If the particleType is -1 the particle is inactive.
    var type = data.particleType[i];
    if (type != -1) {
      if (data.useIntegers) {
        // Compute random displacement.
        var motion = new List<int>.generate(
            3,
            (int d) =>
                rng.nextInt(data.randomWalkStep[type].oddSize) -
                data.randomWalkStep[type].sub,
            growable: false);

        // Random displacement in units
        var displacement = new Vector3(motion[0] / data.voxelsPerUnit,
            motion[1] / data.voxelsPerUnit, motion[2] / data.voxelsPerUnit);

        // Temporarily store the position.
        var position = new Vector3(
            data.particleUint16Position[i * 3 + 0] / data.voxelsPerUnit,
            data.particleUint16Position[i * 3 + 1] / data.voxelsPerUnit,
            data.particleUint16Position[i * 3 + 2] / data.voxelsPerUnit);

        // Correct displacement by processing it with every membrane.
        for (var m = 0; m < data.membranes.length; m++) {
          if (data.membranes[m]
              .blockParticleMotion(type, position, displacement)) {
            continue OUTER;
          }
        }

        // No block; apply the motion.
        for (var d = 0; d < 3; d++) {
          data.particleUint16Position[i * 3 + d] += motion[d];
        }
      } else {
        // Compute random displacement.
        var motion = new List<double>.generate(3,
            (int d) => (rng.nextDouble() - .5) * data.randomWalkStep[type].size,
            growable: false);

        // Displacement vector
        var displacement = new Vector3(motion[0], motion[1], motion[2]);

        // Temporarily store the position.
        var position = new Vector3(
            data.particleFloatPosition[i * 3 + 0],
            data.particleFloatPosition[i * 3 + 1],
            data.particleFloatPosition[i * 3 + 2]);

        // Correct displacement by processing it with every membrane.
        for (var m = 0; m < data.membranes.length; m++) {
          if (data.membranes[m]
              .blockParticleMotion(type, position, displacement)) {
            continue OUTER;
          }
        }

        // No block; apply the motion.
        for (var d = 0; d < 3; d++) {
          data.particleFloatPosition[i * 3 + d] += motion[d];
        }
      }
    }
  }
}

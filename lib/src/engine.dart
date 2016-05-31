// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class BromiumEngine {
  Uint16List particleType;
  Float32List particlePosition;
  Float32List particleColor;

  BromiumEngine() {
    // Create 1.000.000 particles.
    int count = 1000000;
    particleType = new Uint16List(count);
    particlePosition = new Float32List(count * 3);
    particleColor = new Float32List(count * 4);

    var rng = new Random();
    for (int i = 0, j = 0, k = 0; i < count; i++, j += 3, k += 4) {
      // Give all particles a random position.
      particlePosition[j] = (rng.nextDouble() - .5) * 10;
      particlePosition[j + 1] = (rng.nextDouble() - .5) * 10;
      particlePosition[j + 2] = 0.0;

      // Color all particles white.
      particleColor[k] = particlePosition[j] > 0 ? 0.0 : 1.0;
      particleColor[k + 1] = 0.0;
      particleColor[k + 2] = particlePosition[j] > 0 ? 1.0 : 0.0;
      particleColor[k + 3] = 1.0;
    }
  }

  void step() {
    var rng = new Random();
    for (int i = 0; i < particlePosition.length; i++) {
      // Give all particles a random displacement.
      particlePosition[i] += (rng.nextDouble() - .5) * 0.1;
    }
  }
}

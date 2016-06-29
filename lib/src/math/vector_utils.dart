// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.math;

/// Generate a random vector between (0, 0, 0) and (1, 1, 1).
Vector3 randomVector3(Random rng) {
  return new Vector3(rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
}

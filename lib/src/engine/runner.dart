// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.engine;

/// Simulation runner
class SimulationRunner {
  /// Simulation data
  Simulation data;

  /// Benchmarking data
  Benchmark benchmark;

  /// Get buffer for rendering
  ByteBuffer getBuffer() {
    data.updateBufferHeader();
    return data.buffer;
  }

  /// Set the loaded simulation
  void loadSimulation(Simulation sim) {
    // Replace data.
    data = sim;

    // Reset caches.
  }

  /// Run a single simulation cycle.
  void cycle() {
    // Apply random motion to particles. If there are no membranes we can use
    // the fast algorithm.
    if (data.membranes.isEmpty) {
      particlesRandomMotionFast(data);
    } else {
      particlesRandomMotionNormal(data);
    }

    // Find bind reactions using the fast voxel method.
    if (data.bindReactions.isNotEmpty) {
      reactionsFastVoxel(data);
    }

    // Apply unbind reactions using random unbinding.
    if (data.unbindReactions.isNotEmpty) {
      reactionsUnbindRandom(data);
    }
  }
}

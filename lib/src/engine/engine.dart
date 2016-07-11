// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.engine;

/// Simulation controller
class BromiumEngine {
  /// Simulation data
  Simulation data;

  /// Render buffer
  RenderBuffer renderBuffer = new RenderBuffer();

  /// Run simulation on the 3D render thread.
  bool onRenderThread = true;

  /// Run simulation in isolate.
  bool inIsolate = false;

  /// Simulation is running
  bool isRunning = false;

  /// Reaction cache.
  ReactionAlgorithmCache reactionCache;

  BromiumEngine(this.data) {
    data.updateBufferHeader();
    renderBuffer.update(data.buffer);
  }

  /// Run one simulation cycle.
  void cycle() {
    if (!inIsolate && isRunning) {
      kineticsRandomMotion(data);
      reactionsFastVoxel(data);
      reactionsUnbindRandom(data);
      data.updateBufferHeader();
      renderBuffer.update(data.buffer);
    }
  }

  /// Pause simulation.
  void pause() {
    isRunning = false;
  }

  /// Run simulation.
  void run() {
    isRunning = true;
  }

  /// Print benchmarks.
  void printBenchmarks() {
    // Not yet implemented
  }
}

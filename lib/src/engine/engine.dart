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

  BromiumEngine();

  /// Load a new simulation.
  void loadSimulation(Simulation sim) {
    data = sim;

    // Prepare for 3D rendering.
    data.updateBufferHeader();
    renderBuffer.update(data.buffer);
  }

  /// Run one simulation cycle.
  void cycle() {
    if (!inIsolate && isRunning) {
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

      // Update the simulation buffer header.
      data.updateBufferHeader();

      // Update the render buffer.
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

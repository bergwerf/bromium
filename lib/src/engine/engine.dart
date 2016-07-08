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

  /// Is the simulation data updated?
  bool changed = true;

  /// Run simulation on the 3D render thread.
  bool onRenderThread = true;

  /// Run simulation in isolate.
  bool inIsolate = false;

  BromiumEngine(this.data);

  /// Run one simulation cycle.
  void cycle() {
    if (!inIsolate) {
      data.updateBufferHeader();
      renderBuffer.update(data.buffer);
    }
  }
}

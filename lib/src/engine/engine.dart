// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.engine;

/// Simulation controller
class BromiumEngine {
  /// Render buffer
  RenderBuffer renderBuffer = new RenderBuffer();

  /// Run simulation in isolate.
  bool inIsolate = false;

  /// Simulation is running
  bool isRunning = false;

  /// Isolate controller
  SimulationIsolate isolate = new SimulationIsolate();

  /// Simulation runner for the main thread
  SimulationRunner runner = new SimulationRunner();

  BromiumEngine([this.inIsolate = true]);

  /// Load a new simulation.
  Future loadSimulation(Simulation sim) async {
    if (inIsolate) {
      await isolate.loadSimulation(sim);
    } else {
      runner.loadSimulation(sim);
    }
    run();
  }

  /// Update render data.
  void update() {
    if (isRunning) {
      if (inIsolate) {
        renderBuffer.update(isolate.lastBuffer);
      } else {
        runner.cycle();
        renderBuffer.update(runner.getBuffer());
      }
    }
  }

  /// Pause simulation.
  Future pause() async {
    if (inIsolate) {
      await isolate.pause();
      isRunning = false;
    } else {
      isRunning = false;
    }
  }

  /// Run simulation.
  void run() {
    isRunning = true;
    if (inIsolate) {
      isolate.resume();
    }
  }

  /// Print benchmarks.
  void printBenchmarks() {
    if (inIsolate) {
      isolate.retrieveBenchmarks().then((Benchmark benchmark) {
        benchmark.printAllMeasurements();
      });
    } else {
      runner.benchmark.printAllMeasurements();
    }
  }
}

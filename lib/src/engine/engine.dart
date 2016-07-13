// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.engine;

/// Simulation controller
class BromiumEngine {
  /// Info logger
  final Logger logger = new Logger('BromiumEngine');

  /// Render buffer
  final RenderBuffer renderBuffer = new RenderBuffer();

  /// Isolate controller
  final SimulationIsolate isolate = new SimulationIsolate();

  /// Simulation runner for the main thread
  final SimulationRunner runner = new SimulationRunner();

  /// Run simulation in isolate.
  bool inIsolate = false;

  /// Simulation is running
  bool isRunning = false;

  BromiumEngine([this.inIsolate = true]);

  /// Load a new simulation.
  Future loadSimulation(Simulation sim) async {
    log.group(logger, 'loadSimulation');
    logger.info('Loading new simulation...');

    if (inIsolate) {
      await isolate.loadSimulation(sim);
    } else {
      runner.loadSimulation(sim);
    }
    resume();

    log.groupEnd();
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
    logger.info('Pausing engine...');

    if (inIsolate && isolate.isRunning) {
      await isolate.pause();
      isRunning = false;
    } else {
      isRunning = false;
    }

    logger.info('Paused engine.');
  }

  /// Resume simulation runner.
  void resume() {
    logger.info('Resuming engine...');

    isRunning = true;
    if (inIsolate) {
      isolate.resume();
    }
  }

  /// Print benchmarks.
  void printBenchmarks() {
    if (inIsolate) {
      logger.info('Retrieving benchmarks from isolate...');
      isolate.retrieveBenchmarks().then((Benchmark benchmark) {
        benchmark.printAllMeasurements();
      });
    } else {
      runner.benchmark.printAllMeasurements();
    }
  }
}

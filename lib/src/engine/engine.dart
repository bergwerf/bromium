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

  BromiumEngine({this.inIsolate: true});

  /// Load a new simulation.
  Future<bool> loadSimulation(Simulation sim) async {
    log.group(logger, 'loadSimulation');
    logger.info('Loading new simulation...');

    await pause();

    var result = false;
    if (inIsolate) {
      result = await isolate.loadSimulation(sim);
    } else {
      runner.loadSimulation(sim);
      result = true;
    }

    logger.info('Loaded simulation.');

    // Resume and return.
    resume();
    log.groupEnd();
    return result;
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
    if (isRunning) {
      logger.info('Pausing engine...');

      if (inIsolate && isolate.isRunning) {
        await isolate.pause();
        isRunning = false;
      } else {
        isRunning = false;
      }

      logger.info('Paused engine.');
    }
  }

  /// Resume simulation runner.
  void resume() {
    if (!isRunning) {
      logger.info('Resuming engine...');

      isRunning = true;
      if (inIsolate) {
        if (isolate.resume()) {
          logger.info('Resumed engine.');
        }
      } else {
        logger.info('Resumed engine.');
      }
    }
  }

  /// Switch to rendering in an isolate.
  Future<bool> switchToIsolate() async {
    log.group(logger, 'switchToIsolate');
    logger.info('Switching to isolate...');

    if (!inIsolate) {
      // Pause.
      await pause();

      // Get simulation data.
      var simulation = runner.data;

      // Load simulation and return.
      inIsolate = true;
      var result = await loadSimulation(simulation);
      log.groupEnd();
      return result;
    } else {
      logger.warning('Already rendering in isolate!');
      log.groupEnd();
      return false;
    }
  }

  /// Switch to rendering on the main thread.
  Future<bool> switchToMainThread() async {
    log.group(logger, 'switchToMainThread');
    logger.info('Switching to main thread...');

    if (inIsolate) {
      // Pause.
      await pause();

      // Get simulation data.
      var simulation = await isolate.retrieveSimulation();

      // Load simulation and return.
      inIsolate = false;
      var result = await loadSimulation(simulation);
      log.groupEnd();
      return result;
    } else {
      logger.warning('Already rendering on main thread!');
      log.groupEnd();
      return false;
    }
  }

  /// Print benchmarks.
  void printBenchmarks() {
    if (inIsolate) {
      logger.info('Retrieving benchmarks from isolate...');
      isolate.retrieveBenchmarks().then((Benchmark benchmark) {
        logger.info('Retrieved benchmarks.');
        benchmark.printAllMeasurements();
      });
    } else {
      runner.benchmark.printAllMeasurements();
    }
  }
}

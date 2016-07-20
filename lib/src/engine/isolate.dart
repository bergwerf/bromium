// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.engine;

/// Isolate controller for running a [SimulationRunner] inside a Dart isolate.
class SimulationIsolate {
  // Isolate trigger flags.
  static const flagRenderBatch = 1;
  static const flagSendBenchmark = 2;
  static const flagSendSimulation = 4;

  /// Show messages from within the isolate.
  static bool showIsolateLog = true;

  /// Most recent render buffer from the isolate.
  ByteBuffer lastBuffer;

  /// Info logger
  final Logger logger = new Logger('bromium.engine.SimulationIsolate');

  /// Primary isolate.
  Isolate _isolate;

  /// Data receive port.
  ReceivePort _receivePort;

  /// Trigger send port.
  SendPort _sendPort;

  /// Number of computed cycles so far.
  int _computedCycles = 0;

  /// Number of cycles per batch.
  static const _cyclesPerBatch = 128;

  /// Run simulation.
  bool _keepRunning = false;

  /// Isolate is paused.
  bool _paused = true;

  /// Pause isolate.
  bool _terminate = false;

  /// Isolate pause completer.
  Completer<bool> _pauser;

  /// Isolate terminate completer.
  Completer<bool> _terminator;

  /// Retrieve benchmark completer
  Completer<Benchmark> _benchmarkCompleter;

  /// Retrieve simulation completer
  Completer<Simulation> _simulationCompleter;

  /// Find if there is an active isolate.
  bool get activeIsolate => _isolate != null;

  /// Find if an isolate is running.
  bool get isRunning => activeIsolate && !_paused;

  /// Retrieve benchmark information.
  Future<Benchmark> retrieveBenchmarks() {
    logger.info('Retrieving benchmarks...');

    if (activeIsolate) {
      _sendPort.send(flagSendBenchmark);
      _benchmarkCompleter = new Completer<Benchmark>();
      return _benchmarkCompleter.future;
    } else {
      logger.severe('No isolate is active!');
      return new Future<Benchmark>.value();
    }
  }

  /// Retrieve simulation data.
  Future<Simulation> retrieveSimulation() {
    logger.info('Retrieving simulation...');

    if (activeIsolate) {
      _sendPort.send(flagSendSimulation);
      _simulationCompleter = new Completer<Simulation>();
      return _simulationCompleter.future;
    } else {
      logger.severe('No isolate is active!');
      return new Future<Simulation>.value();
    }
  }

  /// Kill isolate.
  Future<bool> kill() {
    logger.info('Killing isolate...');

    if (activeIsolate) {
      if (_keepRunning) {
        // The isolate is running, so we have to escape from the event cycle.
        _terminator = new Completer<bool>();
        _keepRunning = false;
        _terminate = true;
        _isolate.kill();
        return _terminator.future;
      } else {
        // The isolate is paused, so it should shut down without further issues.
        _isolate.kill();
        _isolate = null;
        return new Future<bool>.value(true);
      }
    } else {
      logger.warning('No isolate is active!');
      return new Future<bool>.value(false);
    }
  }

  /// Pause isolate.
  Future<bool> pause() {
    logger.info('Pausing isolate...');

    if (_keepRunning) {
      _pauser = new Completer<bool>();
      _keepRunning = false;
      return _pauser.future;
    } else {
      logger.warning('No isolate is running!');
      return new Future<bool>.value(false);
    }
  }

  /// Resume isolate.
  bool resume() {
    logger.info('Resuming isolate...');

    if (activeIsolate) {
      if (_sendPort != null) {
        if (!_keepRunning) {
          _computedCycles = 0;
          _terminate = false; // Stop termination.
          _keepRunning = true;
          _paused = false;

          // Trigger new batch.
          _sendPort.send(flagRenderBatch);
          return true;
        } else {
          logger.warning('Isolate is already running!');
          return false;
        }
      } else {
        logger.severe('Isolate is active but we have no send port!');
        return false;
      }
    } else {
      logger.warning('No isolate is active!');
      return false;
    }
  }

  /// Load simulation to a new isolate.
  /// Returns if the simulation was loaded succefully.
  Future<bool> loadSimulation(Simulation simulation) async {
    log.group(logger, 'loadSimulation');
    logger.info('Loading new simulation...');

    // Completer for this method. loadSimulation completes when the send port
    // has been retrieved.
    var loadingCompleter = new Completer<bool>();

    // Prepare some render data untill the isolate has really started up.
    simulation.updateBufferHeader();
    lastBuffer = simulation.buffer;

    // Kill current isolate.
    if (activeIsolate) {
      await kill();
    }

    // Setup receive port for the new isolate.
    _receivePort = new ReceivePort();
    _receivePort.listen((dynamic msg) {
      if (msg is ByteBuffer) {
        // Retrieved render data.
        _computedCycles++;

        // Trigger new batch.
        if (_computedCycles % _cyclesPerBatch == 0 && _sendPort != null) {
          if (_keepRunning) {
            // Trigger new batch.
            _sendPort.send(flagRenderBatch);
          } else if (_terminate) {
            // Isolate was terminated.
            logger.info('Killed isolate.');
            _isolate = null;
            _terminate = false;
            _paused = true;
            _terminator.complete(true);
          } else {
            // Isolate was paused.
            logger.info('Paused isolate.');
            _paused = true;
            _pauser.complete(true);
          }
        }

        // Replace old simulation buffer.
        lastBuffer = msg;
      } else if (msg is Benchmark) {
        logger.info('Retrieved benchmarks.');

        // Redirect benchmark to completer.
        _benchmarkCompleter.complete(msg);
      } else if (msg is SimulationZ) {
        logger.info('Retrieved compressed simulation.');

        // Redirect unpacked simulation to completer.
        _simulationCompleter.complete(msg.unpack());
      } else if (msg is SendPort) {
        logger.info('Retrieved isolate send port.');

        // Store send port.
        _sendPort = msg;

        // Complete the simulation loading.
        loadingCompleter.complete(true);
      }
    });

    // Spawn new isolate.
    // Note: do not start running by default.
    _keepRunning = false;
    _paused = true;
    try {
      logger.info('Spawning isolate...');
      _isolate = await Isolate.spawn(
          _isolateRunner,
          new Tuple2<SendPort, SimulationZ>(
              _receivePort.sendPort, new SimulationZ(simulation)));
    } catch (e, stackTrace) {
      // Log error and return false.
      logger.severe('Failed to spawn isolate!', e, stackTrace);
      log.groupEnd();
      return false;
    }

    logger.info('Succesfully spawned isolate.');
    log.groupEnd();
    return loadingCompleter.future;
  }

  /// Isolate simulation runner
  static void _isolateRunner(Tuple2<SendPort, SimulationZ> setup) {
    isolateLog('Started isolate.');
    isolateLog('Unpacking simulation...');
    final simulation = setup.item2.unpack();
    isolateLog('Finished unpacking the simulation.');

    final sendPort = setup.item1;
    final runner = new SimulationRunner();
    runner.loadSimulation(simulation);

    // Batch computation mechanism
    final triggerPort = new ReceivePort();
    triggerPort.listen((int flags) {
      if (flags & flagRenderBatch != 0) {
        // Render n frames.
        for (var i = _cyclesPerBatch; i > 0; i--) {
          runner.cycle();
          sendPort.send(runner.getBuffer());
        }
      }
      if (flags & flagSendBenchmark != 0) {
        sendPort.send(runner.benchmark);
      }
      if (flags & flagSendSimulation != 0) {
        sendPort.send(new SimulationZ(simulation));
      }
    });
    sendPort.send(triggerPort.sendPort);
  }

  /// Print isolate message.
  static void isolateLog(String message) {
    if (showIsolateLog) {
      print('[ISOLATE] $message');
    }
  }
}

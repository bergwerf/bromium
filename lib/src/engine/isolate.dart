// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.engine;

/// Isolate controller for running a [SimulationRunner] inside a Dart isolate.
class SimulationIsolate {
  /// Show messages from within the isolate.
  static bool showIsolateLog = true;

  /// Most recent render buffer from the isolate.
  ByteBuffer lastBuffer;

  /// Info logger
  final Logger logger = new Logger('SimulationIsolate');

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

  /// Get benchmarks after the next batch.
  bool _getBenchmarks = false;

  /// Run simulation on isolate.
  bool _run = false;

  /// Pause isolate.
  bool _terminate = false;

  /// Isolate pause completer.
  Completer<Null> _pauser;

  /// Isolate terminate completer.
  Completer<Null> _terminator;

  /// Retrieve benchmarks completer
  Completer<Benchmark> _benchmarkCompleter;

  /// Find if there is an active isolate.
  bool get activeIsolate => _isolate != null;

  /// Find if an isolate is running.
  bool get isRunning => activeIsolate && _run;

  /// Retrieve benchmark information.
  Future<Benchmark> retrieveBenchmarks() {
    _getBenchmarks = true;
    _benchmarkCompleter = new Completer<Benchmark>();
    return _benchmarkCompleter.future;
  }

  /// Kill isolate.
  Future<Null> kill() {
    logger.info('Killing isolate...');

    if (activeIsolate) {
      if (_run) {
        // The isolate is running, so we have to escape from the event cycle.
        _terminator = new Completer<Null>();
        _run = false;
        _terminate = true;
        _isolate.kill();
        return _terminator.future;
      } else {
        // The isolate is paused, so it should shut down without further issues.
        _isolate.kill();
        _isolate = null;
        return new Future.value();
      }
    } else {
      logger.warning('No isolate is running.');
      return new Future.value();
    }
  }

  /// Pause isolate.
  Future<Null> pause() {
    logger.info('Pausing isolate...');

    if (_run) {
      _pauser = new Completer<Null>();
      _run = false;
      return _pauser.future;
    } else {
      logger.warning('No isolate is running.');
      return new Future.value();
    }
  }

  /// Resume isolate.
  void resume() {
    if (!_run) {
      logger.info('Resuming isolate...');

      if (activeIsolate) {
        _computedCycles = 0;
        _run = true;

        if (_sendPort != null) {
          // Trigger new batch without retrieving benchmarks.
          _sendPort.send(false);
        }
      } else {
        logger.warning('No isolate is running!');
      }
    }
  }

  /// Load simulation to a new isolate.
  /// Returns if the simulation was loaded succefully.
  Future<bool> loadSimulation(Simulation simulation) async {
    log.group(logger, 'loadSimulation');
    logger.info('Loading new simulation...');

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
        _computedCycles++;

        // Trigger new batch.
        if (_computedCycles % _cyclesPerBatch == 0 && _sendPort != null) {
          if (_run) {
            // Trigger new batch.
            _sendPort.send(_getBenchmarks);
            _getBenchmarks = false;
          } else if (_terminate) {
            // Isolate was terminated.
            logger.info('Killed isolate.');
            _isolate = null;
            _terminate = false;
            _terminator.complete();
          } else {
            // Isolate was paused.
            logger.info('Paused isolate.');
            _pauser.complete();
          }
        }

        // Replace old simulation buffer.
        lastBuffer = msg;
      } else if (msg is Benchmark) {
        // Redirect benchmark to completer.
        _benchmarkCompleter.complete(msg);
      } else if (msg is SendPort) {
        // Store send port.
        _sendPort = msg;

        // Trigger first batch.
        _sendPort.send(false);
      }
    });

    // Spawn new isolate.
    _computedCycles = 0;
    _run = true;
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
    return true;
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
    triggerPort.listen((bool sendBenchmark) {
      // Render n frames.
      for (var i = _cyclesPerBatch; i > 0; i--) {
        runner.cycle();
        sendPort.send(runner.getBuffer());
      }

      if (sendBenchmark) {
        sendPort.send(runner.benchmark);
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

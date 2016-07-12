// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.engine;

/// Isolate controller for running a [SimulationRunner] inside a Dart isolate.
class SimulationIsolate {
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

  /// Isolate terminate completer.
  Completer<Null> _terminator;

  /// Retrieve benchmarks completer
  Completer<Benchmark> _benchmarkCompleter;

  /// Retrieve benchmark information.
  Future<Benchmark> retrieveBenchmarks() {
    _getBenchmarks = true;
    _benchmarkCompleter = new Completer<Benchmark>();
    return _benchmarkCompleter.future;
  }

  /// Kill isolate.
  Future<Null> kill() {
    logger.info('Killing isolate...');

    if (_isolate != null) {
      _terminator = new Completer<Null>();
      _run = false;
      _terminate = true;
      _isolate.kill();
      return _terminator.future;
    } else {
      return new Future.value();
    }
  }

  /// Pause isolate.
  void pause() {
    logger.info('Pausing isolate...');
    _run = false;
  }

  /// Resume isolate.
  void resume() {
    logger.info('Resuming isolate...');
    if (_isolate != null) {
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

  /// Load simulation to a new isolate.
  /// Returns if the simulation was loaded succefully.
  Future<bool> loadSimulation(Simulation simulation) async {
    logger.info('group: loadSimulation');
    logger.info('Loading new simulation...');

    // Set last buffer temporarily using the given simulation buffer.
    simulation.updateBufferHeader();
    lastBuffer = simulation.buffer;

    // Kill current isolate.
    await kill();

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
            _isolate = null;
            _terminate = false;
            _terminator.complete();
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

      // Note: the simulation logger cannot be sent to the isolate, so we have
      // to temporarily remove it.
      simulation.removeLogger();
      var particleData = simulation.compressParticlesList();
      simulation.particles.clear();
      _isolate = await Isolate.spawn(
          _isolateRunner,
          new Tuple3<SendPort, Simulation, ByteBuffer>(
              _receivePort.sendPort, simulation, particleData.buffer));
    } catch (e, stackTrace) {
      // Log error and return false.
      logger.severe('Failed to spawn isolate!', e, stackTrace);
      logger.info('groupEnd');
      return false;
    }

    logger.info('Succesfully spawned isolate.');
    logger.info('groupEnd');
    return true;
  }

  /// Isolate simulation runner
  static void _isolateRunner(Tuple3<SendPort, Simulation, ByteBuffer> setup) {
    var sendPort = setup.item1;
    var runner = new SimulationRunner();

    // Repair simulation.
    setup.item2.rebuildParticles(new Int16List.view(setup.item3));
    setup.item2.addLogger();

    runner.loadSimulation(setup.item2);

    // Internal benchmark
    var benchmark = new Benchmark();

    // Batch computation mechanism
    var triggerPort = new ReceivePort();
    triggerPort.listen((bool sendBenchmark) {
      // Render n frames.
      for (var i = _cyclesPerBatch; i > 0; i--) {
        runner.cycle();
        sendPort.send(runner.getBuffer());
      }

      if (sendBenchmark) {
        sendPort.send(benchmark);
      }
    });
    sendPort.send(triggerPort.sendPort);
  }
}

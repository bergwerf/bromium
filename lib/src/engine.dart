// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Simulation engine
class BromiumEngine {
  /// Simulation
  Simulation sim;

  /// Benchmarks
  BromiumBenchmark benchmark;

  /// Array sort reaction kinetics cache.
  Uint32List _sortCache;

  /// Simulation render isolate.
  Isolate _simIsolate;

  /// Isolate data receive port.
  ReceivePort _receivePort;

  /// Isolate trigger send port.
  SendPort _sendPort;

  /// Run simulation on isolate.
  bool _runIsolate = false;

  /// Print benchmarks in next isolate cycle batch.
  bool _printIsolateBenchmarks = false;

  /// Number of computed cycles so far.
  int nCycles = 0;

  /// Number of cycles computed per batch by the isolate runner.
  static const nBatchCycles = 128;

  /// Constructor
  BromiumEngine() {
    // Start benchmark helper.
    benchmark = new BromiumBenchmark();
  }

  /// Clear all old particles and allocate new ones.
  void loadSimulation(
      VoxelSpace space,
      ParticleDict particles,
      List<ParticleSet> sets,
      List<BindReaction> bindReactions,
      List<Membrane> membranes) {
    benchmark.start('load new simulation');

    // Sanity check bind reactions.
    bindReactions.forEach((BindReaction r) {
      if (!particles.isValidBindReaction(r)) {
        throw new ArgumentError('bindReactions contains an invalid reaction');
      }
    });

    // Update simulation info.
    var info = new SimulationInfo(
        space,
        particles.data,
        bindReactions,
        new List<DomainType>.generate(
            membranes.length, (int i) => membranes[i].domain.type));

    // Compute total particle count.
    int nParticles = 0;
    sets.forEach((ParticleSet s) {
      nParticles += s.count * particles.computeParticleSize(s.type);
    });

    // Allocate new simulation data.
    var buffer = new SimulationBuffer.fromDimensions(
        particles.data.length, nParticles, membranes.length);

    // Load membrane data into simulation buffer.
    for (var i = 0; i < membranes.length; i++) {
      buffer.setMembraneDimensions(i, membranes[i].domain.getDims());
      for (var t = 0; t < buffer.nTypes; t++) {
        buffer.setInwardPermeability(i, t, membranes[i].inwardPermeability[t]);
        buffer.setOutwardPermeability(
            i, t, membranes[i].outwardPermeability[t]);
      }
    }

    // Build simulation object.
    // Its important to do this after loading the membrane permeability values
    // or the Simulation.membranes will be initialized incorrectly.
    sim = new Simulation(info, buffer);

    // Create new random number generator for computing random positions.
    var rng = new Random();

    // Loop through all particle sets.
    var p = 0;
    for (var i = 0; i < sets.length; i++) {
      // Assign coordinates and color to each particle.
      for (var j = 0; j < sets[i].count; j++, p++) {
        // Assign particle type, random position, and color.
        sim.buffer.pType[p] = sets[i].type;
        sim.setParticleCoords(p, sets[i].domain.computeRandomPoint(rng));
        sim.setParticleColor(p, info.particleInfo[sets[i].type].rgba);
      }
    }

    // Set inactive particles.
    for (; p < sim.buffer.nParticles; p++) {
      sim.buffer.pType[p] = -1;
    }

    // Allocate sort cache.
    _sortCache = new Uint32List.fromList(
        new List<int>.generate(sim.buffer.nParticles, (int i) => i));

    benchmark.end('load new simulation');
  }

  /// Compute scene center and scale.
  Tuple2<Vector3, double> computeSceneDimensions() {
    var center = new Vector3.zero();
    var _min = sim.buffer.pCoords.first.toDouble();
    var _max = _min;

    for (var i = 0; i < sim.buffer.pCoords.length; i += 3) {
      center.add(new Vector3(
          sim.buffer.pCoords[i + 0].toDouble(),
          sim.buffer.pCoords[i + 1].toDouble(),
          sim.buffer.pCoords[i + 2].toDouble()));

      for (var d = 0; d < 3; d++) {
        _min = min(_min, sim.buffer.pCoords[i + d]);
        _max = max(_max, sim.buffer.pCoords[i + d]);
      }
    }
    center.scale(1 / sim.buffer.nParticles);

    return new Tuple2<Vector3, double>(center, _max - _min);
  }

  /// Simulate one step in the particle simulation.
  void step() {
    benchmark.start('simulation cycle');
    benchmark.start('particle motion');

    computeMotion(sim);

    benchmark.end('particle motion');
    benchmark.start('particle reactions');

    computeReactionsWithArraySort(sim, _sortCache, benchmark);

    benchmark.end('particle reactions');
    benchmark.end('simulation cycle');

    nCycles++;
  }

  /// Print all available benchmark information.
  void printBenchmarks() {
    _printIsolateBenchmarks = true;
  }

  /// Kill existing rendering isolate.
  void killIsolate() {
    if (_simIsolate != null) {
      _simIsolate.kill();
      _runIsolate = false;
    }
  }

  /// Pause isolate.
  void pauseIsolate() {
    _runIsolate = false;
  }

  /// Resume isolate.
  void resumeIsolate() {
    if (_simIsolate != null) {
      nCycles = 0;
      _runIsolate = true;

      if (_sendPort != null) {
        _sendPort.send(true);
      }
    }
  }

  /// Start new isolate for rendering.
  Future restartIsolate() async {
    nCycles = 0;
    killIsolate();

    // Setup receive port for the new isolate.
    _receivePort = new ReceivePort();
    _receivePort.listen((dynamic msg) {
      if (msg is ByteBuffer) {
        nCycles++;
        if (_sendPort != null && _runIsolate && nCycles % nBatchCycles == 0) {
          _sendPort.send(_printIsolateBenchmarks);
          _printIsolateBenchmarks = false;
        }
        sim.buffer = new SimulationBuffer.fromByteBuffer(msg);
      } else if (msg is BromiumBenchmark) {
        // Print all benchmarks (this was a response to .printBenchmarks())
        benchmark.printAllMeasurements();
        msg.printAllMeasurements();
        print('Number of computed cycles: $nCycles');
      } else if (msg is SendPort) {
        _sendPort = msg;
        _sendPort.send(_printIsolateBenchmarks); // First trigger
        _printIsolateBenchmarks = false;
      }
    });

    // Spawn new isolate.
    _runIsolate = true;
    _simIsolate = await Isolate.spawn(
        _isolateRunner,
        new Tuple3<SendPort, SimulationInfo, ByteBuffer>(
            _receivePort.sendPort, sim.info, sim.buffer.byteBuffer));
  }

  /// Isolate simulation runner
  static Future _isolateRunner(
      Tuple3<SendPort, SimulationInfo, ByteBuffer> setup) async {
    // Extract setup data.
    var sendPort = setup.item1;
    var sim = new Simulation(
        setup.item2, new SimulationBuffer.fromByteBuffer(setup.item3));

    // Create sort cache.
    var sortCache = new Uint32List.fromList(
        new List<int>.generate(sim.buffer.nParticles, (int i) => i));

    // Some dirty benchmarking.
    var benchmark = new BromiumBenchmark();

    var triggerPort = new ReceivePort();
    sendPort.send(triggerPort.sendPort);
    triggerPort.listen((bool sendBenchmark) {
      // Render 100 frames.
      for (var i = nBatchCycles; i > 0; i--) {
        benchmark.start('isolate simulation cycle');
        benchmark.start('isolate simulation motion');

        computeMotion(sim);

        benchmark.end('isolate simulation motion');
        benchmark.start('isolate simulation reactions');

        computeReactionsWithArraySort(sim, sortCache, benchmark);

        benchmark.end('isolate simulation reactions');
        benchmark.end('isolate simulation cycle');

        sendPort.send(sim.buffer.byteBuffer);
      }

      if (sendBenchmark) {
        sendPort.send(benchmark);
      }
    });
  }
}

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
  Isolate _simulationIsolate;

  /// Isolate data receive port.
  ReceivePort _receivePort;

  /// Isolate trigger send port.
  SendPort _sendPort;

  /// Number of computed cycles so far.
  int _isolateComputedCycles = 0;

  /// Number of cycles computed per batch by the isolate runner.
  static const _isolateCyclesPerBatch = 128;

  /// Get benchmarks in next isolate cycle batch.
  bool _isolateGetBenchmarks = false;

  /// Run simulation on isolate.
  bool _isolateRun = false;

  /// Pause isolate.
  bool _isolateTerminate = false;

  /// Isolate terminate completer.
  Completer<Null> _isolateTerminator;

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
      List<UnbindReaction> unbindReactions,
      List<Membrane> membranes,
      List<Trigger> triggers,
      int initialExtraInactive) {
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
        unbindReactions,
        new List<DomainType>.generate(
            membranes.length, (int i) => membranes[i].domain.type),
        triggers);

    // Compute total particle count.
    int nParticles = 0;
    sets.forEach((ParticleSet s) {
      nParticles += s.count * particles.computeParticleSize(s.type);
    });

    // Allocate new simulation data.
    var buffer = new SimulationBuffer.fromDimensions(
        particles.data.length,
        nParticles + initialExtraInactive,
        membranes.length,
        initialExtraInactive);

    // Load membrane data into simulation buffer.
    for (var i = 0; i < membranes.length; i++) {
      buffer.setMembraneDims(i, membranes[i].domain.getDims(), true);
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
        var point = sets[i].domain.computeRandomPoint(rng);
        sim.buffer.pType[p] = sets[i].type;
        sim.buffer.setParticleCoords(p, point);
        sim.buffer.setParticleColor(p, info.particleInfo[sets[i].type].rgba);

        // Assign particle parent membranes.
        for (var m = 0; m < membranes.length; m++) {
          if (membranes[m].domain.containsVec(point)) {
            sim.buffer.setParentMembrane(p, m);
          }
        }
      }
    }

    // Fill particle buffer with inactive particles.
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
    var center = sim.buffer.getParticleVec(0);
    var _min = center.clone();
    var _max = center.clone();

    for (var p = 1; p < sim.buffer.activeParticleCount; p++) {
      var particle = sim.buffer.getParticleVec(p);
      Vector3.min(_min, particle, _min);
      Vector3.max(_max, particle, _max);
      center.add(particle);
    }
    center.scale(1 / sim.buffer.activeParticleCount);

    return new Tuple2<Vector3, double>(center, (_max - _min).length);
  }

  /// Simulate one step in the particle simulation.
  void cycle() {
    _cycle(sim, benchmark, _sortCache);
  }

  /// Simulate one step in the particle simulation.
  static void _cycle(
      Simulation sim, BromiumBenchmark benchmark, Uint32List sortCache) {
    benchmark.start('simulation cycle');
    benchmark.start('random motion');

    computeMotion(sim);

    benchmark.end('random motion');
    benchmark.start('bind reactions');

    computeReactionsWithArraySort(sim, sortCache, benchmark);

    benchmark.end('bind reactions');
    benchmark.start('unbind reactions');

    applyUnbindReactions(sim);

    benchmark.end('unbind reactions');
    benchmark.start('membrane dynamics');

    ellipsoidMembraneDynamicsWithProjection(sim);

    benchmark.end('membrane dynamics');
    benchmark.start('triggers');

    for (var trigger in sim.info.triggers) {
      if (trigger.check(sim)) {
        trigger.run(sim);
      }
    }

    benchmark.end('triggers');
    benchmark.end('simulation cycle');
  }

  /// Print all available benchmark information.
  void printBenchmarks() {
    if (_isolateRun) {
      _isolateGetBenchmarks = true;
    } else {
      benchmark.printAllMeasurements();
    }
  }

  /// Kill existing rendering isolate.
  Future<Null> killIsolate() {
    if (_simulationIsolate != null) {
      _isolateTerminator = new Completer<Null>();
      _isolateRun = false;
      _isolateTerminate = true;
      _simulationIsolate.kill();
      return _isolateTerminator.future;
    } else {
      return new Future.value();
    }
  }

  /// Pause isolate.
  void pauseIsolate() {
    _isolateRun = false;
  }

  /// Resume isolate.
  void resumeIsolate() {
    if (_simulationIsolate != null) {
      _isolateComputedCycles = 0;
      _isolateRun = true;

      if (_sendPort != null) {
        _sendPort.send(false);
      }
    }
  }

  /// Start new isolate for rendering.
  Future restartIsolate() async {
    await killIsolate();

    // Setup receive port for the new isolate.
    _receivePort = new ReceivePort();
    _receivePort.listen((dynamic msg) {
      if (msg is ByteBuffer) {
        _isolateComputedCycles++;

        // Trigger new batch.
        if (_isolateComputedCycles % _isolateCyclesPerBatch == 0 &&
            _sendPort != null) {
          if (_isolateRun) {
            // Trigger new batch.
            _sendPort.send(_isolateGetBenchmarks);
            _isolateGetBenchmarks = false;
          } else if (_isolateTerminate) {
            // Isolate was terminated.
            _simulationIsolate = null;
            _isolateTerminate = false;
            _isolateTerminator.complete();
          }
        }

        // Replace old simulation buffer.
        sim.buffer = new SimulationBuffer.fromByteBuffer(msg);
      } else if (msg is BromiumBenchmark) {
        // Print isolate benchmarks.
        msg.printAllMeasurements();
      } else if (msg is SendPort) {
        // Store send port to start triggering computations.
        _sendPort = msg;
        _sendPort.send(false); // First trigger
      }
    });

    // Spawn new isolate.
    _isolateComputedCycles = 0;
    _isolateRun = true;
    _simulationIsolate = await Isolate.spawn(
        _isolateRunner,
        new Tuple3<SendPort, SimulationInfo, ByteBuffer>(
            _receivePort.sendPort, sim.info, sim.buffer.byteBuffer));
  }

  /// Isolate simulation runner
  static Future _isolateRunner(
      Tuple3<SendPort, SimulationInfo, ByteBuffer> setup) async {
    // Extract setup data.
    var sendPort = setup.item1;

    // Create simulation (recast DomainType to fix the enum issue in isolates).
    var sim = new Simulation(
        new SimulationInfo(
            setup.item2.space,
            setup.item2.particleInfo,
            setup.item2.bindReactions,
            setup.item2.unbindReactions,
            new List<DomainType>.generate(setup.item2.membranes.length,
                (int i) => DomainType.values[setup.item2.membranes[i].index]),
            setup.item2.triggers),
        new SimulationBuffer.fromByteBuffer(setup.item3));

    // Create sort cache.
    var sortCache = new Uint32List.fromList(
        new List<int>.generate(sim.buffer.nParticles, (int i) => i));

    // Internal benchmark
    var benchmark = new BromiumBenchmark();

    // Batch computation mechanism
    var triggerPort = new ReceivePort();
    triggerPort.listen((bool sendBenchmark) {
      // Render 100 frames.
      for (var i = _isolateCyclesPerBatch; i > 0; i--) {
        _cycle(sim, benchmark, sortCache);
        sendPort.send(sim.buffer.byteBuffer);
      }

      if (sendBenchmark) {
        sendPort.send(benchmark);
      }
    });
    sendPort.send(triggerPort.sendPort);
  }
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Simulation engine
class BromiumEngine {
  /// Simulation info
  SimulationInfo info;

  /// Simulation data
  SimulationBuffer data;

  /// Benchmarks
  BromiumBenchmark benchmark;

  /// Array sort reaction kinetics cache.
  Uint32List _sortCache;

  /// Simulation render isolate.
  Isolate _simIsolate;

  /// Isolate communication receive port.
  ReceivePort _receivePort;

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
    info = new SimulationInfo(
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
    data = new SimulationBuffer.fromDimensions(
        particles.data.length, nParticles, membranes.length);

    // Load membrane data into simulation buffer.
    for (var i = 0; i < membranes.length; i++) {
      data.setMembraneDimensions(i, membranes[i].domain.getDims());
      for (var t = 0; t < data.nTypes; t++) {
        data.setInwardPermeability(i, t, membranes[i].inwardPermeability[t]);
        data.setOutwardPermeability(i, t, membranes[i].outwardPermeability[t]);
      }
    }

    // Create new random number generator for computing random positions.
    var rng = new Random();

    // Loop through all particle sets.
    var p = 0;
    for (var i = 0; i < sets.length; i++) {
      // Assign coordinates and color to each particle.
      for (var j = 0; j < sets[i].count; j++, p++) {
        // Assign particle type, random position, and color.
        data.pType[p] = sets[i].type;
        setParticleCoords(data, p, sets[i].domain.computeRandomPoint(rng));
        setParticleColor(data, p, info.particleInfo[sets[i].type].rgba);
      }
    }

    // Set inactive particles.
    for (; p < data.nParticles; p++) {
      data.pType[p] = -1;
    }

    // Allocate sort cache.
    _sortCache = new Uint32List.fromList(
        new List<int>.generate(data.nParticles, (int i) => i));

    // Start new render isolate.
    _startIsolate();

    benchmark.end('load new simulation');
  }

  /// Compute scene center and scale.
  Tuple2<Vector3, double> computeSceneDimensions() {
    var center = new Vector3.zero();
    var _min = data.pCoords.first.toDouble();
    var _max = _min;

    for (var i = 0; i < data.pCoords.length; i += 3) {
      center.add(new Vector3(data.pCoords[i + 0].toDouble(),
          data.pCoords[i + 1].toDouble(), data.pCoords[i + 2].toDouble()));

      for (var d = 0; d < 3; d++) {
        _min = min(_min, data.pCoords[i + d]);
        _max = max(_max, data.pCoords[i + d]);
      }
    }
    center.scale(1 / data.nParticles);

    return new Tuple2<Vector3, double>(center, _max - _min);
  }

  /// Simulate one step in the particle simulation.
  void step() {
    var sim = new Sim(info, data);

    benchmark.start('simulation step');
    benchmark.start('particle motion');

    computeMotion(sim);

    benchmark.end('particle motion');
    benchmark.start('particle reactions');

    computeReactionsWithArraySort(sim, _sortCache);

    benchmark.end('particle reactions');
    benchmark.end('simulation step');
  }

  /// Isolated step runnner.
  static void _isolateRunner(
      Tuple3<SendPort, SimulationInfo, ByteBuffer> setup) {
    // Extract setup data.
    var sendPort = setup.item1;
    var sim =
        new Sim(setup.item2, new SimulationBuffer.fromByteBuffer(setup.item3));

    // Create sort cache.
    var sortCache = new Uint32List.fromList(
        new List<int>.generate(sim.data.nParticles, (int i) => i));

    // Continuously recompute.
    while (true) {
      computeMotion(sim);
      computeReactionsWithArraySort(sim, sortCache);
      sendPort.send(sim.data.byteBuffer);
    }
  }

  /// Start new isolate for rendering
  Future _startIsolate() async {
    if (_simIsolate != null) {
      _simIsolate.kill();
    }

    // Setup receive port for the new isolate.
    _receivePort = new ReceivePort();
    _receivePort.listen((ByteBuffer buffer) {
      data = new SimulationBuffer.fromByteBuffer(buffer);
    });

    // Spawn new isolate.
    _simIsolate = await Isolate.spawn(
        _isolateRunner,
        new Tuple3<SendPort, SimulationInfo, ByteBuffer>(
            _receivePort.sendPort, info, data.byteBuffer));
  }
}

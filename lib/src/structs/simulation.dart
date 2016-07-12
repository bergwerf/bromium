// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// All information during a simulation. All data is final. All underlying
/// dynamic data is backed by the [buffer].
class Simulation {
  /// Buffer max size (300MB)
  static const maxBufferSize = 100000000;

  /// Buffer particles cap
  static const particlesCap = 10000;

  /// Buffer membranes cap
  static const membranesCapBytes = 120;

  /// Info logger
  Logger logger;

  /// Byte buffer for data that must be continously streamed to the frontend.
  /// This contains 3D render input and simulation state information this is
  /// displayed in the user interface. This buffer can be parsed using
  /// [RenderBuffer].
  ByteBuffer buffer;

  /// Simulation dimensions
  ///
  /// The buffer header is not updated continuously to avoid the misconception
  /// that it should be used for anything else than raw buffer reading.
  final SimulationHeader header;

  /// Store particles offset in the buffer for convenience. This value can
  /// be calculated from the [header].
  int particlesOffset = 0;

  /// Particle types
  final List<ParticleType> particleTypes;

  /// Bind reactions
  final List<BindReaction> bindReactions;

  /// Unbind reactions
  final List<UnbindReaction> unbindReactions;

  /// Particles
  final List<Particle> particles;

  /// Membranes
  final List<Membrane> membranes;

  /// Load simulation from loose data.
  Simulation(this.particleTypes, List<BindReaction> bindReactions,
      List<UnbindReaction> unbindReactions)
      : header =
            new SimulationHeader(bindReactions.length, unbindReactions.length),
        bindReactions = bindReactions,
        unbindReactions = unbindReactions,
        particles = [],
        membranes = [] {
    addLogger();
    logger.info('group: Simulation');

    // Compute particles offset.
    particlesOffset = SimulationHeader.byteCount +
        Reaction.byteCount *
            (header.bindReactionCount + header.unbindReactionCount);

    // Transfer all data to a single byte buffer.
    transfer(0, 0);

    logger.info('groupEnd');
  }

  /// Unsafe add particle to buffer.
  void _addParticle(Particle particle) {
    // Transfer particle to the data buffer.
    particle.transfer(
        buffer, particlesOffset + Particle.byteCount * particles.length);

    // Add particle to the particle list.
    particles.add(particle);
  }

  /// Utility for [_addParticle] with only a [type] and [position]. Also
  /// computes the entered membranes. You can specify the entered mebmranes to
  /// prevent an number of expensive ray projections.
  void _easyAddParticle(int type, Vector3 position, [List<int> entered]) {
    final _type = particleTypes[type];
    final particle = new Particle(type, position, _type.displayColor,
        _type.displayRadius, _type.stepRadius);
    _addParticle(particle);

    // Set entered membranes.
    if (entered != null) {
      particle.entered.insertAll(0, entered);
    } else {
      // Compute entered membranes using ray projection.
      updateParticleEntered(particle);
    }
  }

  /// Add new particles by randomly generating [n] positions within [domain].
  void addRandomParticles(int type, Domain domain, int n) {
    logger.info('group: addRandomParticles');
    logger.info('''
Add $n particles:
  type: $type
  domain: ${domain.toString()}''');

    _rescaleBuffer(n, 0);

    // Generate particles.
    for (; n > 0; n--) {
      _easyAddParticle(type, domain.computeRandomPoint());
    }

    logger.info('groupEnd');
  }

  /// Add a membrane to the buffer.
  void addMembrane(Membrane membrane) {
    logger.info('group: addMembrane');
    logger.info('''
Add membrane:
  domain: ${membrane.domain.toString()}''');

    _rescaleBuffer(0, membrane.sizeInBytes);

    membrane.transfer(buffer, header.membranesOffset + allMembraneBytes);
    membranes.add(membrane);

    /// Update the entered membranes for all particles.
    for (var particle in particles) {
      updateParticleEntered(particle);
    }

    logger.info('groupEnd');
  }

  /// Remove particle.
  void removeParticle(int p) {
    /// Swap particle p with the last particle unless p is the last particle.
    if (p < particles.length - 1) {
      /// Transfer the last particle to the byte buffer spot of particle p.
      particles.last.transfer(buffer, particlesOffset + p * Particle.byteCount);

      /// Replace particle p with the last particle.
      particles[p] = particles.removeLast();
    } else {
      particles.removeLast();
    }
  }

  /// Edit the given particle type.
  void editParticleType(Particle particle, int type) {
    final _type = particleTypes[type];
    particle.type = type;
    particle.setColor(_type.displayColor);
    particle.setRadius(_type.displayRadius);
    particle.setStepRadius(_type.stepRadius);
  }

  /// Recompute the entered membranes for the given particle using ray
  /// projections.
  void updateParticleEntered(Particle particle) {
    var ray =
        new Ray.originDirection(particle.position, new Vector3(1.0, .0, .0));
    var entered = new List<Tuple2<int, double>>();

    for (var m = 0; m < membranes.length; m++) {
      final domain = membranes[m].domain;
      if (domain.contains(particle.position)) {
        var proj = domain.computeRayIntersections(ray);
        entered.add(new Tuple2<int, double>(m, proj.reduce(max)));
      }
    }

    // Sort entered in descending order.
    entered.sort((Tuple2<int, double> a, Tuple2<int, double> b) =>
        b.item2.compareTo(a.item2));

    // Updated entered membranes.
    particle.entered.clear();
    for (var tuple in entered) {
      particle.entered.add(tuple.item1);
    }
  }

  /// Bind two particles.
  void bindParticles(int a, int b, int type) {
    /// As a general rule, the new position will be the position of the particle
    /// with the largest display radius.
    final largest = particleTypes[particles[a].type].displayRadius >
        particleTypes[particles[b].type].displayRadius ? a : b;

    /// Set particle a to the new type.
    ///
    /// Note that we have to do this before removing b or the index of particle
    /// a might have changed (only if a is the last particle).
    final particle = particles[a];
    editParticleType(particle, type);
    particle.setPosition(particles[largest].position);

    /// Remove particle b.
    removeParticle(b);
  }

  /// Apply multiple bind reactions (takes care of index displacement).
  void applyBindReactions(List<Tuple3<int, int, int>> rxns) {
    // In all reactions set item1 to the smallest of {item1, item2}.
    for (var i = 0; i < rxns.length; i++) {
      if (rxns[i].item1 > rxns[i].item2) {
        rxns[i] = new Tuple3<int, int, int>(
            rxns[i].item2, rxns[i].item1, rxns[i].item3);
      }
    }

    // Sort reactions in descending order using item2.
    rxns.sort((Tuple3<int, int, int> a, Tuple3<int, int, int> b) =>
        b.item2 - a.item2);

    // Apply reactions
    for (var rxn in rxns) {
      bindParticles(rxn.item1, rxn.item2, rxn.item3);
    }
  }

  /// Unbind particle into products
  void unbindParticle(int p, List<int> products) {
    /// If products.isNotEmpty, particle p can be replaced with products.first.
    if (products.isNotEmpty) {
      // Add first product.
      final type = products.first;
      final particle = particles[p];
      editParticleType(particle, type);

      // Add other reaction products.
      _rescaleBuffer(products.length - 1, 0);
      for (var i = 1; i < products.length; i++) {
        _easyAddParticle(products[i], particle.position, particle.entered);
      }
    } else {
      /// Remove particle p.
      removeParticle(p);
    }
  }

  /// Compute bounding box that encloses all particles.
  Aabb3 particlesBoundingBox() {
    if (particles.isNotEmpty) {
      var _min = particles[0].position.clone();
      var _max = particles[0].position.clone();

      for (var p = 1; p < particles.length; p++) {
        Vector3.min(_min, particles[p].position, _min);
        Vector3.max(_max, particles[p].position, _max);
      }

      return new Aabb3.minMax(_min, _max);
    } else {
      return new Aabb3.minMax(new Vector3.zero(), new Vector3.all(1.0));
    }
  }

  /// Transfer all dynamic data to a new buffer. This method is primarily used
  /// to resize the byte buffer.
  void transfer(int addParticles, int addMembraneBytes) {
    logger.info('''
Transfer to a larger buffer:
  particle count: ${particles.length}
  extra particles: $addParticles
  extra membrane bytes: $addMembraneBytes''');

    /// Buffer layout:
    /// - header variables
    ///   * number of bind reactions
    ///   * number of unbind reactions
    ///   * number of particles
    ///   * membrane buffer offset (due to particles cap)
    ///   * number of membranes
    /// - bind reaction probabilities
    /// - unbind reaction probabilities
    /// - particles + cap
    /// - membranes + cap

    // Compute new buffer size.
    var membranesOffset = SimulationHeader.byteCount +
        Reaction.byteCount * (bindReactions.length + unbindReactions.length) +
        Particle.byteCount * (particles.length + addParticles + particlesCap);

    var bufferSize = membranesOffset +
        allMembraneBytes +
        addMembraneBytes +
        membranesCapBytes;

    // Create new buffer.
    var newBuffer = new ByteData(bufferSize).buffer;

    // Transfer header.
    var offset = header.transfer(newBuffer, 0);
    header.membranesOffset = membranesOffset;

    // Transfer reactions and particles.
    for (var bindReaction in bindReactions) {
      offset = bindReaction.transfer(newBuffer, offset);
    }
    for (var unbindReaction in unbindReactions) {
      offset = unbindReaction.transfer(newBuffer, offset);
    }
    for (var particle in particles) {
      offset = particle.transfer(newBuffer, offset);
    }

    // Skip particles cap and transfer membranes.
    offset = membranesOffset;
    for (var membrane in membranes) {
      offset = membrane.transfer(newBuffer, offset);
    }

    // Replace the local buffer.
    buffer = newBuffer;
  }

  /// Get the number of bytes in the render buffer that are allocated by
  /// membranes.
  int get allMembraneBytes {
    int count = 0;
    for (var membrane in membranes) {
      count += membrane.sizeInBytes;
    }
    return count;
  }

  /// Scale buffer so that it can contain the additional number of particles.
  void _rescaleBuffer(int addParticles, int addMembraneBytes) {
    // Check if enough buffer space is available and tranfer data to a larger
    // buffer if neccesary.

    if (addParticles > 0) {
      var finalParticlesOffset = particlesOffset +
          Particle.byteCount * (particles.length + addParticles);
      if (finalParticlesOffset < header.membranesOffset) {
        addParticles = 0;
      }
    }
    if (addMembraneBytes > 0) {
      var finalMembranesOffset =
          header.membranesOffset + allMembraneBytes + addMembraneBytes;
      if (finalMembranesOffset <= buffer.lengthInBytes) {
        addMembraneBytes = 0;
      }
    }

    if (addParticles != 0 || addMembraneBytes != 0) {
      transfer(addParticles, addMembraneBytes);
    }
  }

  /// Update the [bufferHeader] values.
  void updateBufferHeader() {
    header.particleCount = particles.length;
    header.membraneCount = membranes.length;
  }

  void removeLogger() {
    logger = null;
  }

  void addLogger() {
    logger = new Logger('Simulation');
  }

  Int16List compressParticlesList() {
    var list = new List<int>();
    for (var particle in particles) {
      list.add(particle.type);
      list.addAll(particle.entered);
      list.add(-1);
    }
    return new Int16List.fromList(list);
  }

  void rebuildParticles(Int16List compressed) {
    var offset = particlesOffset;
    for (var i = 0; i < compressed.length;) {
      // Read particle data.
      var type = compressed[i++];
      var entered = new List<int>();
      var membrane = 0;
      while ((membrane = compressed[i++]) != -1) {
        entered.add(membrane);
      }

      // Create particle.
      final particle = new Particle.empty(type, entered);
      offset = particle.transfer(buffer, offset, false);

      // Add particle.
      particles.add(particle);
    }
  }
}

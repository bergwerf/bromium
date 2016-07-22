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
  Logger logger = new Logger('bromium.structs.Simulation');

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
    log.group(logger, 'Simulation');

    // Compute particles offset.
    particlesOffset = SimulationHeader.byteCount +
        Reaction.byteCount *
            (header.bindReactionCount + header.unbindReactionCount);

    // Transfer all data to a single byte buffer.
    transfer(0, 0);

    log.groupEnd();
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
  Particle _easyAddParticle(int type, Vector3 position, [List<int> entered]) {
    final _type = particleTypes[type];
    final particle = new Particle(
        type, position, _type.displayColor, _type.radius, _type.speed);
    _addParticle(particle);

    // Set entered membranes.
    if (entered != null) {
      particle.entered.insertAll(0, entered);
    } else {
      // Compute entered membranes using ray projection.
      updateParticleEntered(particle);
    }

    return particle;
  }

  /// Add new particles by randomly generating [n] positions within [domain].
  void addRandomParticles(int type, Domain domain, int n,
      {List<Domain> cavities: const []}) {
    log.group(logger, 'addRandomParticles');
    logger.info('''
Add $n particles:
  type: $type
  domain: ${domain.toString()}''');

    _rescaleBuffer(n, 0);

    // Generate particles.
    for (; n > 0; n--) {
      _easyAddParticle(type, domain.computeRandomPoint(cavities: cavities));
    }

    log.groupEnd();
  }

  /// Add a membrane to the buffer.
  void addMembrane(Membrane membrane) {
    log.group(logger, 'addMembrane');
    logger.info('''
Add membrane:
  domain: ${membrane.domain.toString()}''');

    _rescaleBuffer(0, membrane.sizeInBytes);

    membrane.transfer(buffer, header.membranesOffset + allMembraneBytes);
    membranes.add(membrane);

    /// Update the entered membranes for all particles.
    for (final particle in particles) {
      updateParticleEntered(particle);
    }

    log.groupEnd();
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
    particle.radius = _type.radius;
    particle.speed = _type.speed;
  }

  /// Edit the given particle location relative to the given membrane.
  void editParticleLocation(Particle particle, int membrane, int location) {
    switch (location) {
      case Membrane.sticked:
        particle.popEntered(membrane);
        particle.stickTo(membrane, membranes[membrane].domain);
        break;

      case Membrane.inside:
        particle.pushEntered(membrane);
        particle.sticked = -1;
        break;

      case Membrane.outside:
        particle.popEntered(membrane);
        particle.sticked = -1;
        break;
    }
  }

  /// Recompute the entered membranes for the given particle using ray
  /// projections.
  void updateParticleEntered(Particle particle) {
    if (membranes.isEmpty) {
      return;
    }

    // Construct ray.
    var ray =
        new Ray.originDirection(particle.position, new Vector3(1.0, .0, .0));

    // Compute all ray intersections.
    var entered = new List<Tuple2<int, double>>();
    for (var m = 0; m < membranes.length; m++) {
      final domain = membranes[m].domain;
      if (domain.contains(particle.position)) {
        var proj = domain.computeRayIntersections(ray);
        entered.add(new Tuple2<int, double>(m, proj.reduce(max)));
      }
    }

    // Sort intersections in descending order of distance.
    entered.sort((Tuple2<int, double> a, Tuple2<int, double> b) =>
        b.item2.compareTo(a.item2));

    // Updated entered membranes.
    particle.entered.clear();
    for (final tuple in entered) {
      particle.entered.add(tuple.item1);
    }
  }

  /// Bind two particles
  ///
  /// Note that [a] and [b] do not necessarily correspond to
  /// [BindReaction.particleA] and [BindReaction.particleB] since they might be
  /// swapped in both the kinetics algorithm and in [applyBindReactions].
  void bindParticles(int a, int b, int r) {
    final particleA = particles[a];
    final particleB = particles[b];
    final particleC = bindReactions[r].particleC;

    // Set particle a to the new type.
    editParticleType(particleA, particleC.type);

    // If particle C is sticked and particle A and B are also sticked, the
    // position must be interpolated and the sticked property is already set.
    //
    // If particle C is sticked but only particle A or B is sticked, the
    // position and sticked property of particle C must be set to the same
    // values as the initially sticked particle.
    if (particleC.sticked &&
        !(bindReactions[r].particleA.sticked &&
            bindReactions[r].particleB.sticked)) {
      // If particle A is sticked the position and sticked property are already
      // set correctly.
      if (!particleA.isSticked) {
        particleA.sticked = particleB.sticked;
        particleA.setPosition(particleB.position);
      }
    } else {
      // Linearly interpolate between the two particles using their radius as
      // weights.
      var result = new Vector3.zero();
      final weight = particleA.radius + particleB.radius;
      Vector3.mix(particleA.position, particleB.position,
          1 / weight * particleB.radius, result);
      particleA.setPosition(result);
    }

    // Remove particle b.
    removeParticle(b);
  }

  /// Apply multiple bind reactions (takes care of index displacement).
  void applyBindReactions(List<BindReactionItem> rxns) {
    // In all reactions set a to the smallest of {a, b}.
    for (var i = 0; i < rxns.length; i++) {
      if (rxns[i].a > rxns[i].b) {
        rxns[i] = new BindReactionItem(rxns[i].b, rxns[i].a, rxns[i].r);
      }
    }

    // Sort reactions in descending order using b.
    rxns.sort((BindReactionItem a, BindReactionItem b) => b.b - a.b);

    // Apply reactions
    for (final rxn in rxns) {
      bindParticles(rxn.a, rxn.b, rxn.r);
    }
  }

  /// Unbind particle into products
  void unbindParticle(int p, List<ReactionParticle> products) {
    /// If products.isNotEmpty, particle p can be replaced with products.first.
    if (products.isNotEmpty) {
      // Resolve context membrane.
      final particle = particles[p];
      var membrane = -1;
      if (particle.isSticked) {
        membrane = particle.sticked;
      } else if (particle.entered.isNotEmpty) {
        membrane = particle.entered.last;
      }

      // Add first product.
      editParticleType(particle, products.first.type);
      editParticleLocation(particle, membrane, products.first.relativeLocation);

      // Add other reaction products.
      _rescaleBuffer(products.length - 1, 0);

      // Note that i = 0 is already stored in the unbinding particle.
      for (var i = 1; i < products.length; i++) {
        final product = products[i];
        editParticleLocation(
            _easyAddParticle(product.type, particle.position, particle.entered),
            membrane,
            product.relativeLocation);
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
    logger.info('New buffer size: $bufferSize bytes');

    // Create new buffer.
    var newBuffer = new ByteData(bufferSize).buffer;

    // Transfer header.
    var offset = header.transfer(newBuffer, 0);
    header.membranesOffset = membranesOffset;

    // Transfer reactions and particles.
    for (final bindReaction in bindReactions) {
      offset = bindReaction.transfer(newBuffer, offset);
    }
    for (final unbindReaction in unbindReactions) {
      offset = unbindReaction.transfer(newBuffer, offset);
    }
    for (final particle in particles) {
      offset = particle.transfer(newBuffer, offset);
    }

    // Skip particles cap and transfer membranes.
    offset = membranesOffset;
    for (final membrane in membranes) {
      offset = membrane.transfer(newBuffer, offset);
    }

    // Replace the local buffer.
    buffer = newBuffer;

    logger.info('Buffer transfer has finished.');
  }

  /// Get the number of bytes in the render buffer that are allocated by
  /// membranes.
  int get allMembraneBytes {
    int count = 0;
    for (final membrane in membranes) {
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
}

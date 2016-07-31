// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Logical XOR
bool xor(bool a, bool b) => a ? !b : b;

/// Linear interpolation
Vector3 interpolate(Vector3 a, num aWeight, Vector3 b, num bWeight) {
  var result = new Vector3.zero();
  Vector3.mix(a, b, bWeight / (aWeight + bWeight), result);
  return result;
}

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

  /// Particle types (fixed order)
  final List<ParticleType> particleTypes;

  /// Bind reactions (fixed order)
  final List<BindReaction> bindReactions;

  /// Unbind reactions (fixed order)
  final List<UnbindReaction> unbindReactions;

  /// Particles (dynamic order)
  final List<Particle> particles;

  /// Membranes (fixed order)
  final List<Membrane> membranes;

  /// Load simulation from loose data.
  Simulation(List<ParticleType> particleTypes, List<BindReaction> bindReactions,
      List<UnbindReaction> unbindReactions)
      : header = new SimulationHeader(
            particleTypes.length, bindReactions.length, unbindReactions.length),
        particleTypes = particleTypes,
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
    final particle = new Particle(type, position, _type.displayColor,
        _type.speed, _type.radius, membranes.length);
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

    membrane.index = membranes.length;
    membrane.transfer(buffer, header.membranesOffset + allMembraneBytes);
    membranes.add(membrane);

    // Update all particles to integrate the new membrane into the simulation.
    for (final particle in particles) {
      // Update the particle.entered array (the particle might already be
      // inside).
      updateParticleEntered(particle);

      // Add membrane index to particle.minSteps.
      particle.minSteps.add(0);
    }

    log.groupEnd();
  }

  /// Remove particle.
  void removeParticle(int p) {
    // Get the particle to be removed.
    final thisParticle = particles[p];

    // Decrement particle count in all entered membranes.
    for (final entered in thisParticle.entered) {
      membranes[entered].decrementEntered(thisParticle.type);
    }

    // Decrement sticked count if particle is sticked.
    if (thisParticle.isSticked) {
      membranes[thisParticle.sticked].decrementSticked(thisParticle.type);
    }

    // Pick the last particle.
    // Note that this also handles the removal of the particle from the list.
    final lastParticle = particles.removeLast();

    // Swap particle p with the last particle unless p is the last particle.
    // Note that we removed a particle and that p == length if it was the last
    // particle.
    if (p < particles.length) {
      // Transfer the last particle to the byte buffer spot of particle p.
      lastParticle.transfer(buffer, particlesOffset + p * Particle.byteCount);

      // Replace particle p with the last particle.
      particles[p] = lastParticle;
    }
  }

  /// Edit the given particle type.
  void editParticleType(Particle particle, int newType) {
    final oldType = particle.type;

    // Update particle metadata.
    final typeInfo = particleTypes[newType];
    particle.type = newType;
    particle.color = typeInfo.displayColor;
    particle.radius = typeInfo.radius;
    particle.speed = typeInfo.speed;

    // Update particle counting in all entered membranes.
    for (final entered in particle.entered) {
      membranes[entered].changeEnteredType(oldType, newType);
    }

    // Update particle counting in sticked membrane.
    if (particle.isSticked) {
      membranes[particle.sticked].changeStickedType(oldType, newType);
    }
  }

  /// Edit the given particle location relative to the given membrane.
  void editParticleLocation(Particle particle, int ctxMembrane, int location,
      [bool stickProjection = true]) {
    switch (location) {
      case Membrane.sticked:
        // The context membrane cannot be -1.
        if (ctxMembrane == -1) {
          throw new ArgumentError(
              'ctxMembrane cannot be -1 if location is sticked');
        }

        // If the particle is not yet sticked to this membrane, stick it.
        if (particle.sticked != ctxMembrane) {
          if (particle.hasEntered(ctxMembrane)) {
            membranes[ctxMembrane].leaveParticleUnsafe(particle);
          }
          membranes[ctxMembrane].stickParticleUnsafe(particle, stickProjection);
        }
        break;

      case Membrane.inside:
        // If the particle hasn't yet entered the membrane; enter it.
        if (!particle.hasEntered(ctxMembrane)) {
          // If the particle is currently sticked; unstick first.
          if (particle.sticked == ctxMembrane) {
            membranes[ctxMembrane].unstickParticleUnsafe(particle);
          }
          membranes[ctxMembrane].enterParticleUnsafe(particle);
        }
        break;

      case Membrane.outside:
        // If there is a specific membrane and the particle has entered it,
        // leave and unstick the membrane.
        if (ctxMembrane != -1) {
          if (particle.hasEntered(ctxMembrane)) {
            membranes[ctxMembrane].leaveParticleUnsafe(particle);
          } else if (particle.sticked == ctxMembrane) {
            membranes[particle.sticked].unstickParticleUnsafe(particle);
          }
        }
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
    for (final tuple in entered) {
      final membrane = tuple.item1;

      // If this membrane is already included in particle.entered, skip it.
      if (!particle.hasEntered(membrane)) {
        membranes[membrane].enterParticleUnsafe(particle);
      }
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

    // Resolve position.
    if (particleC.sticked &&
        xor(bindReactions[r].particleA.sticked,
            bindReactions[r].particleB.sticked)) {
      // If particle A is sticked, the position is already set correctly. Else
      // particle B must be the sticked particle and we use its position.
      if (!particleA.isSticked) {
        particleA.position = particleB.position;
      }
    } else {
      // Linearly interpolate between the particles using radius as weights.
      particleA.position = interpolate(particleA.position, particleA.radius,
          particleB.position, particleB.radius);
    }

    // Set relative location.
    int contextMembrane =
        max(particleA.getClosestMembrane(), particleB.getClosestMembrane());
    editParticleLocation(
        particleA, contextMembrane, particleC.relativeLocation, false);

    // Remove particle b.
    removeParticle(b);
  }

  /// Apply multiple bind reactions (takes care of index displacement).
  void applyBindReactions(List<BindRxnItem> rxns) {
    // In all reactions set a to the smallest of {a, b}.
    for (var i = 0; i < rxns.length; i++) {
      if (rxns[i].a > rxns[i].b) {
        rxns[i] = new BindRxnItem(rxns[i].b, rxns[i].a, rxns[i].r);
      }
    }

    // Sort reactions in descending order using b.
    //
    // Note that `b` is removed and will change all indices of the particles
    // after `b`. Therefore you should handle the reactions with the largest `b`
    // first. It is not possible for later reactions to be in the range after
    // `b` since all their `b` indices are smaller and all a indices are smaller
    // than the `b` indices.
    rxns.sort((BindRxnItem a, BindRxnItem b) => b.b - a.b);

    // Apply reactions.
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
      final entered = new List<int>.from(particle.entered);
      final ctxMembrane = particle.getClosestMembrane();

      // Add first product.
      editParticleType(particle, products.first.type);
      editParticleLocation(
          particle, ctxMembrane, products.first.relativeLocation);

      // Add other reaction products.
      _rescaleBuffer(products.length - 1, 0);

      // Note that i = 0 is already stored in the unbinding particle.
      for (var i = 1; i < products.length; i++) {
        final product = products[i];
        editParticleLocation(
            _easyAddParticle(product.type, particle.position, entered),
            ctxMembrane,
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
    final membranesOffset = SimulationHeader.byteCount +
        Reaction.byteCount * (bindReactions.length + unbindReactions.length) +
        Particle.byteCount * (particles.length + addParticles + particlesCap);

    final bufferSize = membranesOffset +
        allMembraneBytes +
        addMembraneBytes +
        membranesCapBytes;
    logger.info('New buffer size: $bufferSize bytes');

    // Create new buffer.
    final newBuffer = new ByteData(bufferSize).buffer;

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

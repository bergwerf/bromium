// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:bromium/math.dart';
import 'package:bromium/structs.dart';
import 'package:vector_math/vector_math.dart';

Simulation createTransportDemo() {
  // Setup particle dictionary.
  var p = new Index<ParticleType>();
  p['ATP'] = new ParticleType(Colors.red, 0.03, 0.02);
  p['ADP'] = new ParticleType(Colors.blue, 0.03, 0.02);
  p['P'] = new ParticleType(Colors.gray, 0.03, 0.01);
  p['nutrient'] = new ParticleType(Colors.green, 0.02, 0.03);
  p['channel'] = new ParticleType(Colors.yellow, 0.01, 0.06);
  p['active-channel'] = new ParticleType(Colors.white, 0.01, 0.06);
  p['active-bounded-channel'] = new ParticleType(Colors.gray, 0.01, 0.06);

  // Setup reactions.
  var bindRxn = new Index<BindReaction>();
  var unbindRxn = new Index<UnbindReaction>();
  bindRxn['step 1'] = new BindReaction(
      new ReactionParticle(p['ATP'], Membrane.inside),
      new ReactionParticle(p['channel'], Membrane.sticked),
      new ReactionParticle(p['active-channel'], Membrane.sticked),
      1.0);
  bindRxn['step 2'] = new BindReaction(
      new ReactionParticle(p['active-channel'], Membrane.sticked),
      new ReactionParticle(p['nutrient'], Membrane.outside),
      new ReactionParticle(p['active-bounded-channel'], Membrane.sticked),
      1.0);
  unbindRxn['active-bounded-channel'] = new UnbindReaction(
      new ReactionParticle(p['active-bounded-channel'], Membrane.sticked),
      [
        new ReactionParticle(p['channel'], Membrane.sticked),
        new ReactionParticle(p['ADP'], Membrane.inside),
        new ReactionParticle(p['P'], Membrane.inside),
        new ReactionParticle(p['nutrient'], Membrane.outside)
      ],
      0.1);

  // Create cell membrane.
  var cellMembrane = new Membrane(
      new EllipsoidDomain(new Vector3(.0, .0, .0), new Vector3(2.0, 1.0, 1.0)),
      new Float32List.fromList(new List<double>.filled(7, 0.0)),
      new Float32List.fromList(new List<double>.filled(7, 0.0)),
      new Float32List.fromList(new List<double>.filled(7, 0.0)),
      new Float32List.fromList(new List<double>.filled(7, 0.0)),
      p.length);

  // Setup simulation.
  var simulation = new Simulation(p.data, bindRxn.data, unbindRxn.data);
  simulation.addRandomParticles(p['ATP'], cellMembrane.domain, 5000);
  simulation.addRandomParticles(p['channel'], cellMembrane.domain, 1000);
  simulation.addRandomParticles(
      p['nutrient'],
      new EllipsoidDomain(new Vector3(.0, .0, .0), new Vector3(4.0, 2.0, 2.0)),
      5000,
      cavities: [cellMembrane.domain]);
  simulation.addMembrane(cellMembrane);
  return simulation;
}

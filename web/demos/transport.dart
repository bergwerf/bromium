// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:bromium/math.dart';
import 'package:bromium/structs.dart';
import 'package:vector_math/vector_math.dart';

Simulation createTransportDemo() {
  // Setup particle dictionary.
  final p = new Index<ParticleType>();
  p['ATP'] = new ParticleType(Colors.red, 0.04, 0.01);
  p['ADP'] = new ParticleType(Colors.blue, 0.04, 0.01);
  p['P'] = new ParticleType(Colors.gray, 0.05, 0.005);
  p['nutrient'] = new ParticleType(Colors.green, 0.05, 0.03);
  p['channel'] = new ParticleType(Colors.yellow, 0.02, 0.06);
  p['bounded-channel'] = new ParticleType(Colors.lightGreen, 0.02, 0.06);
  p['active-bounded-channel'] = new ParticleType(Colors.cyan, 0.02, 0.06);

  // Setup reactions.
  final bindRxn = new Index<BindReaction>();
  final unbindRxn = new Index<UnbindReaction>();
  bindRxn['step 1'] = new BindReaction(
      new ReactionParticle(p['channel'], Membrane.sticked),
      new ReactionParticle(p['nutrient'], Membrane.outside),
      new ReactionParticle(p['bounded-channel'], Membrane.sticked),
      1.0);
  bindRxn['step 2'] = new BindReaction(
      new ReactionParticle(p['bounded-channel'], Membrane.sticked),
      new ReactionParticle(p['ATP'], Membrane.inside),
      new ReactionParticle(p['active-bounded-channel'], Membrane.sticked),
      1.0);
  unbindRxn['active-bounded-channel'] = new UnbindReaction(
      new ReactionParticle(p['active-bounded-channel'], Membrane.sticked),
      [
        new ReactionParticle(p['channel'], Membrane.sticked),
        new ReactionParticle(p['ADP'], Membrane.inside),
        new ReactionParticle(p['P'], Membrane.inside),
        new ReactionParticle(p['nutrient'], Membrane.inside)
      ],
      0.5);

  // Create cell membrane.
  final cellMembrane = new Membrane(
      new EllipsoidDomain(new Vector3(.0, .0, .0), new Vector3(2.0, 1.0, 1.0)),
      new Float32List.fromList(new List<double>.filled(7, 0.0)),
      new Float32List.fromList(new List<double>.filled(7, 0.0)),
      new Float32List.fromList(new List<double>.filled(7, 0.0)),
      p.mappedFloat32List({
        'ATP': .0,
        'ADP': .0,
        'P': .0,
        'nutrient': .0,
        'channel': 1.0,
        'bounded-channel': .0,
        'active-bounded-channel': .0
      }),
      p.length);

  // Setup simulation.
  final simulation = new Simulation(p.data, bindRxn.data, unbindRxn.data);
  simulation.addRandomParticles(p['ATP'], cellMembrane.domain, 8000);
  simulation.addRandomParticles(p['channel'], cellMembrane.domain, 1000);
  simulation.addRandomParticles(
      p['nutrient'],
      new EllipsoidDomain(new Vector3(.0, .0, .0), new Vector3(3.0, 1.5, 1.5)),
      5000,
      cavities: [cellMembrane.domain]);
  simulation.addMembrane(cellMembrane);
  return simulation;
}

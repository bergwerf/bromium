// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium.ui;

import 'dart:html';

import 'package:tuple/tuple.dart';
import 'package:bromium/math.dart';
import 'package:bromium/engine.dart';
import 'package:bromium/structs.dart';
import 'package:bromium/renderer.dart';
import 'package:vector_math/vector_math.dart';

part 'data_elements.dart';
part 'data_entries.dart';
part 'data_items.dart';
part 'tabs.dart';

String currentTab = 'particles';

// ignore: non_constant_identifier_names
Element $(String selectors) => document.querySelector(selectors);

// Data items
final particleTypes = new List<ParticleTypeItem>();
final membranes = new List<MembraneItem>();
final setup = new List<SimulationSetupItem>();

// Engine and renderer
final engine = new BromiumEngine();
final canvas = $('#bromium-canvas') as CanvasElement;
final renderer = new BromiumWebGLRenderer(engine, canvas);

void resizeCanvas() {
  canvas.width = $('#view-panel').clientWidth;
  canvas.height = $('#view-panel').clientHeight;
  renderer.updateViewport();
}

void setupUi() {
  window.onResize.listen((_) => resizeCanvas());
  resizeCanvas();

  // Setup tabs.
  final tabs = new Tabs($('#tabs-bar'), $('#tabs-panel'));
  tabs.addTab('Particles');
  tabs.addTab('Membranes');
  tabs.addTab('Reactions');
  tabs.addTab('Domains');
  tabs.addTab('Setup');
  tabs.selectTab('Particles');

  // Add item to current tab.
  $('#btn-add-item').onClick.listen((_) {
    switch (tabs.currentLabel) {
      case 'Particles':
        particleTypes.add(new ParticleTypeItem());
        tabs.currentTabPanel.append(particleTypes.last.node);
        break;

      case 'Membranes':
        membranes.add(new MembraneItem());
        tabs.currentTabPanel.append(membranes.last.node);
        break;

      case 'Setup':
        setup.add(new SimulationSetupItem());
        tabs.currentTabPanel.append(setup.last.node);
        break;
    }
  });

  // Run the simulation.
  $('#btn-run').onClick.listen((_) async {
    // Pause engine and renderer.
    await engine.pause();

    // Get particle types.
    final particleIndex = new Index<ParticleType>();
    for (final item in particleTypes) {
      particleIndex[item.get('Label')] = item.getParticleType();
    }

    // Get membranes.
    final membraneIndex = new Index<Membrane>();
    for (final item in membranes) {
      membraneIndex[item.get('Label')] = item.getMembrane(particleIndex);
    }

    // Setup simulation.
    final simulation = new Simulation(particleIndex.data, [], []);
    for (final item in setup) {
      item.applyToSimulation(simulation, particleIndex, membraneIndex);
    }

    // Load membranes.
    // TODO: batch load membranes.
    for (final membrane in membraneIndex.data) {
      simulation.addMembrane(membrane);
    }

    // Load the simulation.
    var bbox = simulation.particlesBoundingBox();
    await engine.loadSimulation(simulation);
    renderer.focus(bbox);
    renderer.start();
  });

  // Pause the simulation.
  $('#btn-pause').onClick.listen((_) {
    engine.pause();
  });
}

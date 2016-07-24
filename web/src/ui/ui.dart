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
final bindReactions = new List<BindReactionItem>();
final unbindReactions = new List<UnbindReactionItem>();
final domains = new List<DomainItem>();
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
  tabs.addTab('Bind reactions');
  tabs.addTab('Unbind reactions');
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

      case 'Bind reactions':
        bindReactions.add(new BindReactionItem());
        tabs.currentTabPanel.append(bindReactions.last.node);
        break;

      case 'Unbind reactions':
        unbindReactions.add(new UnbindReactionItem());
        tabs.currentTabPanel.append(unbindReactions.last.node);
        break;

      case 'Domains':
        domains.add(new DomainItem());
        tabs.currentTabPanel.append(domains.last.node);
        break;

      case 'Setup':
        setup.add(new SimulationSetupItem());
        tabs.currentTabPanel.append(setup.last.node);
        break;
    }
  });

  // Run the simulation.
  $('#btn-reload').onClick.listen((_) async {
    // Pause engine and renderer.
    await engine.pause();

    // Get particle types.
    final particleIndex = new Index<ParticleType>();
    for (final item in particleTypes) {
      if (item.removed) {
        continue;
      }
      particleIndex[item.get('Label')] = item.data;
    }

    // Get membranes.
    final membraneIndex = new Index<Membrane>();
    for (final item in membranes) {
      if (item.removed) {
        continue;
      }
      membraneIndex[item.get('Label')] = item.createMembrane(particleIndex);
    }

    // Get bind reactions.
    final bindReactionList = new List<BindReaction>();
    for (final item in bindReactions) {
      if (item.removed) {
        continue;
      }
      bindReactionList.add(item.createBindReaction(particleIndex));
    }

    // Get unbind reactions.
    final unbindReactionList = new List<UnbindReaction>();
    for (final item in unbindReactions) {
      if (item.removed) {
        continue;
      }
      unbindReactionList.add(item.createUnbindReaction(particleIndex));
    }

    // Get domains.
    final domainIndex = new Index<Domain>();
    for (final item in domains) {
      if (item.removed) {
        continue;
      }
      domainIndex[item.get('Label')] = item.data;
    }

    // Setup simulation.
    final simulation = new Simulation(
        particleIndex.data, bindReactionList, unbindReactionList);
    for (final item in setup) {
      if (item.removed) {
        continue;
      }
      item.applyToSimulation(
          simulation, particleIndex, membraneIndex, domainIndex);
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
    $('#btn-pause-run').text = 'Pause';
  });

  // Pause the simulation.
  final pauseRunBtn = $('#btn-pause-run');
  pauseRunBtn.onClick.listen((_) async {
    if (engine.isRunning) {
      if (engine.inIsolate) {
        pauseRunBtn.text = 'Pausing...';
        pauseRunBtn.classes.add('disabled');
      }

      await engine.pause();
      pauseRunBtn.text = 'Run';
      pauseRunBtn.classes.remove('disabled');
    } else {
      await engine.resume();
      pauseRunBtn.text = 'Pause';
    }
  });
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium.ui;

import 'dart:html';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';
import 'package:bromium/math.dart';
import 'package:bromium/engine.dart';
import 'package:bromium/structs.dart';
import 'package:bromium/renderer.dart';
import 'package:vector_math/vector_math.dart';

part 'convert.dart';
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

// Quick function for item iteration
List<Item> skipRemovedItems(List<Item> src) {
  final dst = new List<Item>();
  for (final item in src) {
    if (!item.removed) {
      dst.add(item);
    }
  }
  return dst;
}

// Set the canvas size to the #view-panel size
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
  final reloadBtn = $('#btn-reload');
  reloadBtn.onClick.listen((_) async {
    reloadBtn.text = 'Reloading...';
    reloadBtn.classes.add('disabled');

    // Pause engine and renderer.
    await engine.pause();

    // Get particle types.
    final particleIndex = new Index<ParticleType>();
    for (final ParticleTypeItem item in skipRemovedItems(particleTypes)) {
      particleIndex[item.get('Label')] = item.data;
    }

    // Get membranes.
    final membraneIndex = new Index<Membrane>();
    for (final MembraneItem item in skipRemovedItems(membranes)) {
      if (item.removed) {
        continue;
      }
      membraneIndex[item.get('Label')] = item.createMembrane(particleIndex);
    }

    // Get bind reactions.
    final bindReactionList = new List<BindReaction>();
    for (final BindReactionItem item in skipRemovedItems(bindReactions)) {
      if (item.removed) {
        continue;
      }
      bindReactionList.add(item.createBindReaction(particleIndex));
    }

    // Get unbind reactions.
    final unbindReactionList = new List<UnbindReaction>();
    for (final UnbindReactionItem item in skipRemovedItems(unbindReactions)) {
      if (item.removed) {
        continue;
      }
      unbindReactionList.add(item.createUnbindReaction(particleIndex));
    }

    // Get domains.
    final domainIndex = new Index<Domain>();
    for (final DomainItem item in skipRemovedItems(domains)) {
      if (item.removed) {
        continue;
      }
      domainIndex[item.get('Label')] = item.data;
    }

    // Setup simulation.
    final simulation = new Simulation(
        particleIndex.data, bindReactionList, unbindReactionList);
    for (final SimulationSetupItem item in skipRemovedItems(setup)) {
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

    // Update buttons.
    $('#btn-pause-run').text = 'Pause';
    reloadBtn.text = 'Reload';
    reloadBtn.classes.remove('disabled');
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

  // Save the current settings to the local storage on quit.
  window.onUnload.listen((_) {
    final _particleTypes = skipRemovedItems(particleTypes);
    final _membranes = skipRemovedItems(membranes);
    final _bindReactions = skipRemovedItems(bindReactions);
    final _unbindReactions = skipRemovedItems(unbindReactions);
    final _domains = skipRemovedItems(domains);
    final _setup = skipRemovedItems(setup);
    window.localStorage['BromiumData'] = JSON.encode({
      'Particles': toJsonExtra(new List.generate(
          _particleTypes.length, (int i) => _particleTypes[i].collectData())),
      'Membranes': toJsonExtra(new List.generate(
          _membranes.length, (int i) => _membranes[i].collectData())),
      'BindReactions': toJsonExtra(new List.generate(
          _bindReactions.length, (int i) => _bindReactions[i].collectData())),
      'UnbindReactions': toJsonExtra(new List.generate(_unbindReactions.length,
          (int i) => _unbindReactions[i].collectData())),
      'Domains': toJsonExtra(new List.generate(
          _domains.length, (int i) => _domains[i].collectData())),
      'Setup': toJsonExtra(
          new List.generate(_setup.length, (int i) => _setup[i].collectData()))
    });
  });

  // Load the settings that are in the local storage.
  if (window.localStorage.containsKey('BromiumData')) {
    final data = fromJsonExtra(JSON.decode(window.localStorage['BromiumData']));
    for (final item in data['Particles']) {
      particleTypes.add(new ParticleTypeItem(item as Map<String, dynamic>));
      tabs.tabs[0].panelElement.append(particleTypes.last.node);
    }
    for (final item in data['Membranes']) {
      membranes.add(new MembraneItem(item as Map<String, dynamic>));
      tabs.tabs[1].panelElement.append(membranes.last.node);
    }
    for (final item in data['BindReactions']) {
      bindReactions.add(new BindReactionItem(item as Map<String, dynamic>));
      tabs.tabs[2].panelElement.append(bindReactions.last.node);
    }
    for (final item in data['UnbindReactions']) {
      unbindReactions.add(new UnbindReactionItem(item as Map<String, dynamic>));
      tabs.tabs[3].panelElement.append(unbindReactions.last.node);
    }
    for (final item in data['Domains']) {
      domains.add(new DomainItem(item as Map<String, dynamic>));
      tabs.tabs[4].panelElement.append(domains.last.node);
    }
    for (final item in data['Setup']) {
      setup.add(new SimulationSetupItem(item as Map<String, dynamic>));
      tabs.tabs[5].panelElement.append(setup.last.node);
    }
  }
}

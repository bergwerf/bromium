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

// ignore: non_constant_identifier_names
Element $(String selectors) => document.querySelector(selectors);

// Set the canvas size to the #view-panel size
void resizeCanvas(CanvasElement canvas, BromiumWebGLRenderer renderer) {
  canvas.width = $('#view-panel').clientWidth;
  canvas.height = $('#view-panel').clientHeight;
  renderer.updateViewport();
}

void setupUi() {
  final engine = new BromiumEngine();
  final canvas = $('#bromium-canvas') as CanvasElement;
  final renderer = new BromiumWebGLRenderer(engine, canvas);

  // Auto-fit canvas.
  window.onResize.listen((_) => resizeCanvas(canvas, renderer));
  resizeCanvas(canvas, renderer);

  // Create tabs.
  final pTypeTab =
      new Tab<PTypeItem>('Particles', (data) => new PTypeItem(data));
  final membraneTab =
      new Tab<MembraneItem>('Membranes', (data) => new MembraneItem(data));
  final bindRxnTab =
      new Tab<BindRxnItem>('Bind reactions', (data) => new BindRxnItem(data));
  final unbindRxnTab = new Tab<UnbindRxnItem>(
      'Unbind reactions', (data) => new UnbindRxnItem(data));
  final domainTab =
      new Tab<DomainItem>('Domains', (data) => new DomainItem(data));
  final setupTab = new Tab<SetupItem>('Setup', (data) => new SetupItem(data));

  // Add tabs to tab controller.
  final tabs = new Tabs($('#tabs-bar'), $('#tabs-panel'), $('#btn-add-item'));
  tabs.add(pTypeTab);
  tabs.add(membraneTab);
  tabs.add(bindRxnTab);
  tabs.add(unbindRxnTab);
  tabs.add(domainTab);
  tabs.add(setupTab);
  tabs.select('Particles');

  // Run the simulation.
  final reloadBtn = $('#btn-reload');
  reloadBtn.onClick.listen((_) async {
    reloadBtn.text = 'Reloading...';
    reloadBtn.classes.add('disabled');

    // Pause engine.
    await engine.pause();

    // Get particle types.
    final particleIndex = new Index<ParticleType>();
    for (final item in pTypeTab.items) {
      particleIndex[item.get('Label')] = item.data;
    }

    // Get membranes.
    final membraneIndex = new Index<Membrane>();
    for (final item in membraneTab.items) {
      membraneIndex[item.get('Label')] = item.createMembrane(particleIndex);
    }

    // Get bind reactions.
    final bindReactionList = new List<BindReaction>();
    for (final item in bindRxnTab.items) {
      bindReactionList.add(item.createBindReaction(particleIndex));
    }

    // Get unbind reactions.
    final unbindReactionList = new List<UnbindReaction>();
    for (final item in unbindRxnTab.items) {
      unbindReactionList.add(item.createUnbindReaction(particleIndex));
    }

    // Get domains.
    final domainIndex = new Index<Domain>();
    for (final item in domainTab.items) {
      domainIndex[item.get('Label')] = item.data;
    }

    // Setup simulation.
    final simulation = new Simulation(
        particleIndex.data, bindReactionList, unbindReactionList);
    for (final item in setupTab.items) {
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
    window.localStorage['BromiumData'] = JSON.encode({
      'Particles': toJsonExtra(pTypeTab.collectData()),
      'Membranes': toJsonExtra(membraneTab.collectData()),
      'BindReactions': toJsonExtra(bindRxnTab.collectData()),
      'UnbindReactions': toJsonExtra(unbindRxnTab.collectData()),
      'Domains': toJsonExtra(domainTab.collectData()),
      'Setup': toJsonExtra(setupTab.collectData())
    });
  });

  // Load the settings that are in the local storage.
  if (window.localStorage.containsKey('BromiumData')) {
    final data = fromJsonExtra(JSON.decode(window.localStorage['BromiumData']));
    pTypeTab.loadItems(data['Particles'] as List);
    membraneTab.loadItems(data['Membranes'] as List);
    bindRxnTab.loadItems(data['BindReactions'] as List);
    unbindRxnTab.loadItems(data['UnbindReactions'] as List);
    domainTab.loadItems(data['Domains'] as List);
    setupTab.loadItems(data['Setup'] as List);
  }
}

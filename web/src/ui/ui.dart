// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium.ui;

import 'dart:html';

import 'package:tuple/tuple.dart';
import 'package:bromium/structs.dart';
import 'package:vector_math/vector_math.dart';

part 'data_elements.dart';
part 'data_entries.dart';
part 'data_items.dart';
part 'tabs.dart';

String currentTab = 'particles';

// ignore: non_constant_identifier_names
Element $(String selectors) => document.querySelector(selectors);

void setupUi() {
  // Setup tabs.
  final tabs = new Tabs($('#tabs-bar'), $('#tabs-panel'));
  tabs.addTab('Particles');
  tabs.addTab('Membranes');
  tabs.addTab('Reactions');
  tabs.addTab('Domains');
  tabs.addTab('Setup');
  tabs.selectTab('Particles');

  // Add item to current tab.
  document.querySelector('#btn-add-item').onClick.listen((_) {
    var item = new ParticleTypeItem();
    tabs.currentTabPanel.append(item.node);
  });
}

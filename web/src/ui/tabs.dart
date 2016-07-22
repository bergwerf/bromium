// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

/// Wrapper for managing a single tab.
class Tab {
  final String label;

  final SpanElement tabElement;

  final DivElement panelElement;

  Tab(this.label)
      : tabElement = new SpanElement(),
        panelElement = new DivElement() {
    tabElement.text = label;
    tabElement.classes.addAll(['tab-header', 'inactive']);
    panelElement.classes.addAll(['tab-panel', 'hidden']);
  }

  void activate() {
    tabElement.classes.remove('inactive');
    panelElement.classes.remove('hidden');
  }

  void inactivate() {
    tabElement.classes.add('inactive');
    panelElement.classes.add('hidden');
  }
}

/// Wrapper for managing tabs.
class Tabs {
  final DivElement tabsElement, panelsElement;

  final List<Tab> tabs = new List<Tab>();

  int _current = -1;

  Tabs(this.tabsElement, this.panelsElement);

  void addTab(String label) {
    tabs.add(new Tab(label));
    tabsElement.append(tabs.last.tabElement);
    panelsElement.append(tabs.last.panelElement);
    tabs.last.tabElement.onClick.listen((_) => selectTab(label));
  }

  void selectTab(String label) {
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].label == label) {
        tabs[i].activate();
        _current = i;
      } else {
        tabs[i].inactivate();
      }
    }
  }

  DivElement get currentTabPanel {
    if (_current >= 0 && _current < tabs.length) {
      return tabs[_current].panelElement;
    } else {
      return null;
    }
  }
}

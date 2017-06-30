// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

typedef I _GenerateItem<I>(Map<String, dynamic> data);

/// Wrapper for managing a single tab.
class Tab<I extends Item> {
  final String label;

  final SpanElement tabElement;

  final DivElement panelElement;

  final List<I> _items = new List();

  final _GenerateItem<I> itemGenerator;

  Tab(this.label, this.itemGenerator)
      : tabElement = new SpanElement(),
        panelElement = new DivElement() {
    tabElement.text = label;
    tabElement.classes.addAll(['tab-header', 'inactive']);
    panelElement.classes.addAll(['tab-panel', 'hidden']);
  }

  /// Activate this tab.
  void activate() {
    tabElement.classes.remove('inactive');
    panelElement.classes.remove('hidden');
  }

  /// Deactivate this tab.
  void deactivate() {
    tabElement.classes.add('inactive');
    panelElement.classes.add('hidden');
  }

  /// Add new item using the item generator.
  void addItem([Map<String, dynamic> data = null]) {
    _items.add(itemGenerator(data == null ? new Map<String, dynamic>() : data));
    panelElement.append(_items.last.node);
    _items.last.addedToDom();
  }

  /// Load a list of items.
  void loadItems(List data) {
    for (final item in data) {
      addItem(new Map<String, dynamic>.from(item));
    }
  }

  /// Clear all items.
  void clear() {
    _items.clear();
    panelElement.children.clear();
  }

  /// Get all items that have not been removed.
  List<I> get items {
    final dst = new List<I>();
    for (final item in _items) {
      if (!item.removed) {
        dst.add(item);
      }
    }
    return dst;
  }

  /// Collect all item data in one list.
  List<Map<String, dynamic>> collectData() {
    final acviteItems = items;
    return new List<Map<String, dynamic>>.generate(
        acviteItems.length, (i) => acviteItems[i].collectData());
  }
}

/// Wrapper for managing tabs.
class Tabs {
  final DivElement tabsElement, panelsElement;

  final Map<String, Tab> tabs = new Map<String, Tab>();

  String _current = '';

  Tabs(this.tabsElement, this.panelsElement, ButtonElement addButton) {
    addButton.onClick.listen((_) => current.addItem());
  }

  void add(Tab tab) {
    tabs[tab.label] = tab;
    tabsElement.append(tab.tabElement);
    panelsElement.append(tab.panelElement);
    tab.tabElement.onClick.listen((_) => select(tab.label));
  }

  void select(String label) {
    if (tabs.containsKey(_current)) {
      tabs[_current].deactivate();
    }
    tabs[label].activate();
    _current = label;
  }

  Tab get current {
    if (tabs.containsKey(_current)) {
      return tabs[_current];
    } else {
      return null;
    }
  }

  String get currentLabel => current.label;

  DivElement get currentTabPanel => current.panelElement;
}

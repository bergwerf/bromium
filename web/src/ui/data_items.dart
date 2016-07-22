// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

class Item extends CustomElement {
  DivElement node;

  final List<DataEntry> entries;

  Item(this.entries) {
    node = new DivElement()..classes.add('tab-item');
    final table = new TableElement();
    for (final entry in entries) {
      table.append(entry.node);
    }
    node.append(table);
  }

  Map<String, dynamic> collectData() {
    final map = new Map<String, dynamic>();
    for (final entry in entries) {
      map[entry.label] = entry.data;
    }
    return map;
  }
}

class ParticleTypeItem extends Item {
  ParticleTypeItem()
      : super([
          new SimpleEntry('Label', new InputDataElement(type: 'text')),
          new SimpleEntry('Speed', new NumericDataElement(step: 0.001, min: 0)),
          new SimpleEntry(
              'Radius', new NumericDataElement(step: 0.001, min: 0)),
          new SimpleEntry('Color', new ColorDataElement())
        ]);

  ParticleType getParticleType() {
    final data = collectData();
    return new ParticleType(data['Color'].xyz, data['Speed'], data['Radius']);
  }
}

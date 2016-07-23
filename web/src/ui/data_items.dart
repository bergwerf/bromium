// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

/// Base class for data items (basically a group of data entries)
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

  String get(String label) => collectData()[label];
}

/// Data item for a single particle type
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

/// Data item for a single membrane
class MembraneItem extends Item {
  MembraneItem()
      : super([
          new SimpleEntry('Label', new InputDataElement(type: 'text')),
          new SimpleEntry('Type', new ChoiceDataElement(['AABB', 'Ellipsoid'])),
          new SimpleEntry('Center', new Vector3DataElement()),
          new SimpleEntry('Semi-axes', new Vector3DataElement()),
          new MultiSplitEntry(
              'Enter',
              100,
              new NumericDataElement(step: 0.001, min: 0),
              new InputDataElement(type: 'text')),
          new MultiSplitEntry(
              'Leave',
              100,
              new NumericDataElement(step: 0.001, min: 0),
              new InputDataElement(type: 'text')),
          new MultiSplitEntry(
              'Stick on enter',
              100,
              new NumericDataElement(step: 0.001, min: 0),
              new InputDataElement(type: 'text')),
          new MultiSplitEntry(
              'Stick on leave',
              100,
              new NumericDataElement(step: 0.001, min: 0),
              new InputDataElement(type: 'text'))
        ]);

  /// Generate map from MultiSplitEntry tuples.
  static Map<String, num> _generateMap(List<Tuple2<num, String>> list) {
    final map = new Map<String, num>();
    for (final item in list) {
      // Skip empty items.
      if (item.item2.isNotEmpty) {
        map[item.item2] = item.item1;
      }
    }
    return map;
  }

  Membrane getMembrane(Index<ParticleType> particleIndex) {
    final data = collectData();

    // Create domain.
    var domain;
    switch (data['Type']) {
      case 'AABB':
        domain = new AabbDomain(
            new Aabb3.centerAndHalfExtents(data['Center'], data['Semi-axes']));
        break;

      case 'Ellipsoid':
        domain = new EllipsoidDomain(data['Center'], data['Semi-axes']);
        break;
    }

    // Create membrane.
    return new Membrane(
        domain,
        particleIndex.mappedFloat32List(
            _generateMap(data['Enter'] as List<Tuple2<num, String>>)),
        particleIndex.mappedFloat32List(
            _generateMap(data['Leave'] as List<Tuple2<num, String>>)),
        particleIndex.mappedFloat32List(
            _generateMap(data['Stick on enter'] as List<Tuple2<num, String>>)),
        particleIndex.mappedFloat32List(
            _generateMap(data['Stick on leave'] as List<Tuple2<num, String>>)),
        particleIndex.length);
  }
}

/// Data item for a simulation setup entry
class SimulationSetupItem extends Item {
  SimulationSetupItem()
      : super([
          new SimpleEntry('Particle', new InputDataElement(type: 'text')),
          new SimpleEntry('Number', new NumericDataElement(min: 1)),
          new SimpleEntry('Domain', new InputDataElement(type: 'text'))
        ]);

  void applyToSimulation(Simulation simulation,
      Index<ParticleType> particleIndex, Index<Membrane> membraneIndex) {
    final data = collectData();

    // Resolve particle type.
    final particleType = particleIndex[data['Particle']];

    // Resolve domain.
    final domain = membraneIndex.at(data['Domain']).domain;

    simulation.addRandomParticles(particleType, domain, data['Number']);
  }
}

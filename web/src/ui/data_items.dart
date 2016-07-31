// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

/// Base class for data items (basically a group of data entries)
class Item extends CustomElement {
  DivElement node;

  /// All data enties
  final List<DataEntry> entries;

  /// Set to true if the item is removed.
  bool removed = false;

  Item(String title, Map<String, dynamic> data, this.entries) {
    node = new DivElement()..classes.add('tab-item');
    node.append(new SpanElement()
      ..classes.add('item-title')
      ..text = title);
    node.append(new ButtonElement()
      ..innerHtml = '&times;'
      ..style.float = 'right'
      ..onClick.listen((_) {
        node.remove();
        removed = true;
      }));

    // Add all entries to a table.
    final table = new TableElement();
    for (final entry in entries) {
      table.append(entry.node);
      entry.loadData(data);
    }

    // Add table to the node.
    node.append(table);
  }

  /// Collect all entry data.
  Map<String, dynamic> collectData() {
    final map = new Map<String, dynamic>();
    for (final entry in entries) {
      map[entry.label] = entry.data;
    }
    return map;
  }

  /// Get the data of a specified entry.
  dynamic get(String label) {
    for (final entry in entries) {
      if (entry.label == label) {
        return entry.data;
      }
    }
    return null;
  }

  /// Override this to get a trigger when the node is added to the DOM.
  void addedToDom() {}
}

/// Data item for a single particle type
class PTypeItem extends Item {
  PTypeItem(
      [Map<String, dynamic> data = const {
        'Label': '',
        'Speed': 0.01,
        'Radius': 0.01,
        'Color': null
      }])
      : super('Particle type', data, [
          new SimpleEntry('Label', new InputDataElement(type: 'text')),
          new SimpleEntry('Speed', new FloatDataElement(step: 0.001, min: 0.0)),
          new SimpleEntry(
              'Radius', new FloatDataElement(step: 0.001, min: 0.0)),
          new SimpleEntry('Color', new ColorDataElement())
        ]);

  ParticleType get data {
    final data = collectData();
    return new ParticleType(data['Color'].xyz, data['Speed'], data['Radius']);
  }
}

/// Data item for a single membrane
class MembraneItem extends Item {
  /// Membrane particle counts graph
  final ParticleGraph graph;

  /// Membrane index in the current simulation
  int simulationIndex = -1;

  MembraneItem(
      [Map<String, dynamic> data = const {
        'Label': '',
        'Type': 'Ellipsoid',
        'Center': null,
        'Semi-axes': null,
        'Enter': const [],
        'Leave': const [],
        'Stick on enter': const [],
        'Stick on leave': const []
      }])
      : graph = new ParticleGraph(),
        super('Membrane', data, [
          new SimpleEntry('Label', new InputDataElement(type: 'text')),
          new SimpleEntry('Type', new ChoiceDataElement(['AABB', 'Ellipsoid'])),
          new SimpleEntry('Center', new Vector3DataElement()),
          new SimpleEntry('Semi-axes', new Vector3DataElement()),
          new MultiSplitEntry(
              'Enter',
              100,
              new FloatDataElement(step: 0.01, min: 0.0, max: 1.0),
              new InputDataElement(type: 'text'),
              data),
          new MultiSplitEntry(
              'Leave',
              100,
              new FloatDataElement(step: 0.01, min: 0.0, max: 1.0),
              new InputDataElement(type: 'text'),
              data),
          new MultiSplitEntry(
              'Stick on enter',
              100,
              new FloatDataElement(step: 0.01, min: 0.0, max: 1.0),
              new InputDataElement(type: 'text'),
              data),
          new MultiSplitEntry(
              'Stick on leave',
              100,
              new FloatDataElement(step: 0.01, min: 0.0, max: 1.0),
              new InputDataElement(type: 'text'),
              data)
        ]) {
    node.append(new DivElement()
      ..classes.add('particle-graph-titlebar')
      ..append(new SpanElement()
        ..text = 'Graph'
        ..classes.add('particle-graph-title'))
      ..append(new ButtonElement()
        ..style.float = 'right'
        ..innerHtml = '<i class="fa fa-download" aria-hidden="true"></i>'
        ..onClick.listen((_) {
          final data = new Blob(graph.generateCsv().split('\n'), 'text/csv');
          saveAs(data, '${get('Label')}.csv');
        })));
    node.append(graph.node);
  }

  /// Generate map from MultiSplitEntry tuples.
  static Map<String, double> _generateMap(List<Tuple2> list) {
    final map = new Map<String, double>();
    for (final item in list) {
      // Skip empty items.
      if (item.item2.isNotEmpty) {
        map[item.item2] = item.item1;
      }
    }
    return map;
  }

  Membrane createMembrane(Index<ParticleType> particleIndex) {
    final data = collectData();

    // Create domain.
    var domain;
    switch (data['Type']) {
      case 'AABB':
        domain = new AabbDomain(
            new Aabb3.centerAndHalfExtents(data['Center'], data['Semi-axes']));
        break;

      case 'Ellipsoid':
        // In the special case all semi-axes are the same, we create a sphere
        // domain.
        final semiAxes = data['Semi-axes'] as Vector3;
        if (semiAxes.x == semiAxes.y && semiAxes.y == semiAxes.z) {
          domain = new SphereDomain(data['Center'], semiAxes.x);
        } else {
          domain = new EllipsoidDomain(data['Center'], semiAxes);
        }
        break;
    }

    // Create membrane.
    return new Membrane(
        domain,
        particleIndex.mappedFloat32List(
            _generateMap(data['Enter'] as List<Tuple2<double, String>>)),
        particleIndex.mappedFloat32List(
            _generateMap(data['Leave'] as List<Tuple2<double, String>>)),
        particleIndex.mappedFloat32List(_generateMap(
            data['Stick on enter'] as List<Tuple2<double, String>>)),
        particleIndex.mappedFloat32List(_generateMap(
            data['Stick on leave'] as List<Tuple2<double, String>>)),
        particleIndex.length);
  }
}

/// Convert location string to number.
const _convertMembraneLocation = const {
  'inside': Membrane.inside,
  'sticked': Membrane.sticked,
  'outside': Membrane.outside
};

/// Data item for a bind reaction
class BindRxnItem extends Item {
  BindRxnItem(
      [Map<String, dynamic> data = const {
        'Particle A': '',
        'A location': 'outside',
        'Particle B': '',
        'B location': 'outside',
        'Particle C': '',
        'C location': 'outside',
        'Probability': 1
      }])
      : super('Bind reaction', data, [
          new SimpleEntry('Particle A', new InputDataElement(type: 'text')),
          new SimpleEntry('A location',
              new ChoiceDataElement(['inside', 'sticked', 'outside'])),
          new SimpleEntry('Particle B', new InputDataElement(type: 'text')),
          new SimpleEntry('B location',
              new ChoiceDataElement(['inside', 'sticked', 'outside'])),
          new SimpleEntry('Particle C', new InputDataElement(type: 'text')),
          new SimpleEntry('C location',
              new ChoiceDataElement(['inside', 'sticked', 'outside'])),
          new SimpleEntry('Probability',
              new FloatDataElement(step: 0.01, min: 0.0, max: 1.0))
        ]);

  BindReaction createBindReaction(Index<ParticleType> particleIndex) {
    final data = collectData();
    return new BindReaction(
        new ReactionParticle(particleIndex[data['Particle A']],
            _convertMembraneLocation[data['A location']]),
        new ReactionParticle(particleIndex[data['Particle B']],
            _convertMembraneLocation[data['B location']]),
        new ReactionParticle(particleIndex[data['Particle C']],
            _convertMembraneLocation[data['C location']]),
        data['Probability']);
  }
}

/// Data item for an unbind reaction
class UnbindRxnItem extends Item {
  UnbindRxnItem(
      [Map<String, dynamic> data = const {
        'Particle': '',
        'Location': 'outside',
        'Products': const [],
        'Probability': 1
      }])
      : super('Unbind reaction', data, [
          new SimpleEntry('Particle', new InputDataElement(type: 'text')),
          new SimpleEntry('Location',
              new ChoiceDataElement(['inside', 'sticked', 'outside'])),
          new MultiSplitEntry(
              'Products',
              100,
              new ChoiceDataElement(['inside', 'sticked', 'outside']),
              new InputDataElement(type: 'text'),
              data),
          new SimpleEntry('Probability',
              new FloatDataElement(step: 0.01, min: 0.0, max: 1.0))
        ]);

  UnbindReaction createUnbindReaction(Index<ParticleType> particleIndex) {
    final data = collectData();

    // Parse products.
    final productsData = data['Products'] as List<Tuple2<String, String>>;
    final products = new List<ReactionParticle>.generate(
        productsData.length,
        (int i) => new ReactionParticle(particleIndex[productsData[i].item2],
            _convertMembraneLocation[productsData[i].item1]));

    // Create unbind reaction.
    return new UnbindReaction(
        new ReactionParticle(particleIndex[data['Particle']],
            _convertMembraneLocation[data['Location']]),
        products,
        data['Probability']);
  }
}

/// Data item for a domain
class DomainItem extends Item {
  DomainItem(
      [Map<String, dynamic> data = const {
        'Label': '',
        'Type': 'Ellipsoid',
        'Center': null,
        'Semi-axes': null
      }])
      : super('Domain', data, [
          new SimpleEntry('Label', new InputDataElement(type: 'text')),
          new SimpleEntry('Type', new ChoiceDataElement(['AABB', 'Ellipsoid'])),
          new SimpleEntry('Center', new Vector3DataElement()),
          new SimpleEntry('Semi-axes', new Vector3DataElement())
        ]);

  Domain get data {
    final data = collectData();

    // Create domain.
    switch (data['Type']) {
      case 'AABB':
        return new AabbDomain(
            new Aabb3.centerAndHalfExtents(data['Center'], data['Semi-axes']));

      case 'Ellipsoid':
        return new EllipsoidDomain(data['Center'], data['Semi-axes']);

      default:
        return null;
    }
  }
}

/// Data item for a simulation setup entry
class SetupItem extends Item {
  SetupItem(
      [Map<String, dynamic> data = const {
        'Particle': '',
        'Number': 0,
        'Domain': '',
        'Cavities': ''
      }])
      : super('Fill particles', data, [
          new SimpleEntry('Particle', new InputDataElement(type: 'text')),
          new SimpleEntry('Number', new IntDataElement(min: 1)),
          new SimpleEntry('Domain', new InputDataElement(type: 'text')),
          new SimpleEntry('Cavities', new InputDataElement(type: 'text'))
        ]);

  Domain _resolveDomain(
      String label, Index<Membrane> membraneIndex, Index<Domain> domainIndex) {
    if (membraneIndex.contains(label)) {
      return membraneIndex.at(label).domain;
    } else if (domainIndex.contains(label)) {
      return domainIndex.at(label);
    } else {
      return null;
    }
  }

  void applyToSimulation(
      Simulation simulation,
      Index<ParticleType> particleIndex,
      Index<Membrane> membraneIndex,
      Index<Domain> domainIndex) {
    final data = collectData();

    // Resolve particle type.
    final particleType = particleIndex[data['Particle']];

    // Resolve domain.
    final domain = _resolveDomain(data['Domain'], membraneIndex, domainIndex);

    // Resolve cavities.
    final cavityLabels = (data['Cavities'] as String).split(',');
    final cavities = new List<Domain>();
    for (final cavity in cavityLabels) {
      if (cavity.isNotEmpty) {
        final domain =
            _resolveDomain(cavity.trim(), membraneIndex, domainIndex);
        if (domain != null) {
          cavities.add(domain);
        }
      }
    }

    simulation.addRandomParticles(particleType, domain, data['Number'],
        cavities: cavities);
  }
}

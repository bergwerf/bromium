// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

/// Base class for data entries
///
/// A data entry is a wrapper around a [DataElement] that is useful in the UI.
/// The entry always has a label. The data entry is built for usage in a table.
abstract class DataEntry extends CustomElement {
  /// Entry label
  String get label;

  /// The table row that wraps this entry
  @override
  TableRowElement get node;

  /// Get all data in this entry
  dynamic get data;

  /// Load data
  void loadData(Map<String, dynamic> data);
}

/// This entry wraps a single data element
class SimpleEntry extends DataEntry {
  @override
  final TableRowElement node;

  /// The input data element
  final DataElement element;

  @override
  final String label;

  SimpleEntry(this.label, this.element)
      : node = new TableRowElement()
          ..append(new TableCellElement()
            ..append(new SpanElement()
              ..classes.add('label')
              ..text = '$label:'))
          ..append(new TableCellElement()
            ..classes.add('input-cell')
            ..append(element.node));

  @override
  void loadData(Map<String, dynamic> data) {
    if (data.containsKey(label) && data[label] != null) {
      element.value = data[label];
    }
  }

  @override
  dynamic get data => element.value;
}

/// This entry can be used to edit a list of two types of data elements.
class MultiSplitEntry extends DataEntry {
  @override
  TableRowElement node;

  @override
  final String label;

  /// First and second data element that is cloned into each row
  final DataElement a, b;

  /// Pixel width of the first input collumn
  final int colAWidth;

  final List<Tuple2<DataElement, DataElement>> rows =
      new List<Tuple2<DataElement, DataElement>>();

  MultiSplitEntry(
      this.label, this.colAWidth, this.a, this.b, Map<String, dynamic> data) {
    node = new TableRowElement()
      ..append(new TableCellElement()
        ..append(new SpanElement()
          ..style.width = '${colAWidth}px'
          ..classes.add('label')
          ..text = '$label:'))
      ..append(new TableCellElement()
        ..append(new ButtonElement()
          ..style.float = 'right'
          ..text = '+'
          ..onClick.listen((_) => addRow())));
  }

  /// Data has to be loaded seperately because [addRow] requires the parent
  /// node.
  @override
  void loadData(Map<String, dynamic> data) {
    if (data[label] != null) {
      for (final Tuple2 item in data[label]) {
        addRow(item.item1, item.item2);
      }
    }
  }

  /// Add an input row.
  void addRow([aValue = null, bValue = null]) {
    // Add row in internal list.
    final row = new Tuple2<DataElement, DataElement>(a.clone(), b.clone());
    rows.add(row);

    // Load provided values.
    if (aValue != null) {
      row.item1.value = aValue;
    }
    if (bValue != null) {
      row.item2.value = bValue;
    }

    // Create row for the table.
    final tr = new TableRowElement()
      ..append(new TableCellElement()
        ..classes.add('input-cell')
        ..style.width = '${colAWidth}px'
        ..append(row.item1.node))
      ..append(new TableCellElement()
        ..classes.add('input-cell')
        ..append(row.item2.node));

    // Add row to the table.
    if (node.nextNode != null) {
      node.parent.insertBefore(tr, node.nextNode);
    } else {
      node.parent.append(tr);
    }
  }

  @override
  List<Tuple2> get data => new List<Tuple2>.generate(rows.length,
      (int i) => new Tuple2(rows[i].item1.value, rows[i].item2.value));
}

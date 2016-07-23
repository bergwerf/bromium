// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

abstract class DataEntry extends CustomElement {
  String get label;

  TableRowElement get node;

  dynamic get data;
}

class SimpleEntry extends DataEntry {
  final TableRowElement node;

  final DataElement element;

  final String label;

  SimpleEntry(String label, DataElement elm)
      : label = label,
        element = elm,
        node = new TableRowElement()
          ..append(new TableCellElement()
            ..append(new SpanElement()
              ..classes.add('label')
              ..text = '$label:'))
          ..append(new TableCellElement()
            ..classes.add('input-cell')
            ..append(elm.node));

  dynamic get data => element.data;
}

class MultiSplitEntry extends DataEntry {
  TableRowElement node;

  final String label;

  final DataElement a, b;

  final int colAWidth;

  final List<Tuple2<DataElement, DataElement>> rows =
      new List<Tuple2<DataElement, DataElement>>();

  MultiSplitEntry(this.label, this.colAWidth, this.a, this.b) {
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
          ..onClick.listen(onClickAdd)));
  }

  void onClickAdd(MouseEvent event) {
    // Add row in internal list.
    final row = new Tuple2<DataElement, DataElement>(a.clone(), b.clone());
    rows.add(row);

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

  List<Tuple2> get data => new List<Tuple2>.generate(rows.length,
      (int i) => new Tuple2(rows[i].item1.data, rows[i].item2.data));
}

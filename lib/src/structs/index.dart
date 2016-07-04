// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Helper class for creating simulation settings.
class Index<E> {
  /// List of elements in insertion order.
  List<E> data = new List<E>();

  /// Element indices mapped to a string label.
  Map<String, int> _index = new Map<String, int>();

  /// Add new element.
  void operator []=(String label, E element) {
    _index[label] = data.length;
    data.add(element);
  }

  /// Retrieve index.
  int operator [](String label) => _index[label];

  /// Retrieve element by label.
  E at(String label) => data[_index[label]];

  /// Get number of elements.
  int get length => data.length;

  /// Fill list with the values that are assigned to the index labels.
  List mappedList(Map<String, dynamic> map) {
    var list = new List(data.length);
    map.forEach((String label, value) {
      list[_index[label]] = value;
    });
    return list;
  }
}

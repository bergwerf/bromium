// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.structs;

/// Helper class for creating simulation settings.
class Index<E> {
  /// List of elements in insertion order.
  List<E> data = new List<E>();

  /// Element indices mapped to a string label.
  final _index = new Map<String, int>();

  /// Add new element.
  void operator []=(String label, E element) {
    _index[label] = data.length;
    data.add(element);
  }

  /// Retrieve index.
  int operator [](String label) => _index[label];

  /// Retrieve element by label.
  E at(String label) => data[_index[label]];

  /// Check if the given label is contained in the index.
  bool contains(String label) => _index.containsKey(label);

  /// Get number of elements.
  int get length => data.length;

  /// Fill list with the values that are assigned to the index labels.
  List mappedList(Map<String, dynamic> map) {
    final list = new List(data.length);
    map.forEach((label, value) {
      list[_index[label]] = value;
    });
    return list;
  }

  /// Same as [mappedList] but specifically to produce a [Float32List].
  Float32List mappedFloat32List(Map<String, double> map) {
    final list = new Float32List(data.length);
    map.forEach((label, value) {
      list[_index[label]] = value;
    });
    return list;
  }
}

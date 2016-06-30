// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.views;

/// Simple wrapper around [Int8List] to act like a boolean list. Could be
/// extended into real bitset in the future.
class BoolList {
  final Int8List _data;

  BoolList.view(ByteBuffer buffer, [int offset = 0, int length = 0])
      : _data = new Int8List.view(buffer, offset, length);

  bool operator [](int i) => _data[i] == 1;
  void operator []=(int i, bool value) {
    _data[i] = value ? 1 : 0;
  }
}

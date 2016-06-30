// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.views;

/// Base class for primitive views
abstract class _PrimitiveView<T> {
  /// Primitive data
  final ByteData _data;

  /// Construct from buffer. Alternative constructors are not supported because
  /// you should not use these views if you don't need a buffer backend.
  _PrimitiveView.view(ByteBuffer buffer, int length, [int offset = 0])
      : _data = new ByteData.view(buffer, offset, length);

  /// Get value.
  T get();

  /// Set value.
  void set(T value);
}

class Int8View extends _PrimitiveView<int> {
  Int8View.view(ByteBuffer buffer, [int offset = 0])
      : super.view(buffer, 1, offset);

  int get() => _data.getInt8(0);
  void set(int value) => _data.setInt8(0, value);
}

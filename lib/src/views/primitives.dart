// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.views;

/// Base class for primitive views
abstract class _PrimitiveView<T> {
  /// Primitive data
  final ByteData data;

  /// Construct from buffer.
  _PrimitiveView.view(ByteBuffer buffer, int length, [int offset = 0])
      : data = new ByteData.view(buffer, offset, length);

  /// Get value.
  T get();

  /// Set value.
  void set(T value);
}

class Int8View extends _PrimitiveView<int> {
  Int8View(ByteBuffer buffer, [int offset = 0]) : super.view(buffer, 1, offset);
  Int8View.value(int value)
      : super.view(new Int8List.fromList([value]).buffer, 1, 0);

  int get() => data.getInt8(0);
  void set(int value) => data.setInt8(0, value);
}

class Uint8View extends _PrimitiveView<int> {
  Uint8View(ByteBuffer buffer, [int offset = 0])
      : super.view(buffer, 1, offset);
  Uint8View.value(int value)
      : super.view(new Uint8List.fromList([value]).buffer, 1, 0);

  int get() => data.getUint16(0);
  void set(int value) => data.setUint8(0, value);
}

class Int16View extends _PrimitiveView<int> {
  Int16View(ByteBuffer buffer, [int offset = 0])
      : super.view(buffer, 2, offset);
  Int16View.value(int value)
      : super.view(new Int16List.fromList([value]).buffer, 2, 0);

  int get() => data.getInt16(0);
  void set(int value) => data.setInt16(0, value);
}

class Uint16View extends _PrimitiveView<int> {
  Uint16View(ByteBuffer buffer, [int offset = 0])
      : super.view(buffer, 2, offset);
  Uint16View.value(int value)
      : super.view(new Uint16List.fromList([value]).buffer, 2, 0);

  int get() => data.getUint16(0);
  void set(int value) => data.setUint16(0, value);
}

class Int32View extends _PrimitiveView<int> {
  Int32View(ByteBuffer buffer, [int offset = 0])
      : super.view(buffer, 4, offset);
  Int32View.value(int value)
      : super.view(new Int32List.fromList([value]).buffer, 4, 0);

  int get() => data.getInt32(0);
  void set(int value) => data.setInt32(0, value);
}

class Uint32View extends _PrimitiveView<int> {
  Uint32View(ByteBuffer buffer, [int offset = 0])
      : super.view(buffer, 4, offset);
  Uint32View.value(int value)
      : super.view(new Uint32List.fromList([value]).buffer, 4, 0);

  int get() => data.getUint32(0);
  void set(int value) => data.setUint32(0, value);
}

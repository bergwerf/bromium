// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.views;

/// Base class for primitive views
abstract class _PrimitiveView<T> implements Transferrable {
  /// Primitive data
  ByteData data;

  /// Construct from buffer.
  _PrimitiveView.view(ByteBuffer buffer, [int offset = 0]) {
    data = new ByteData.view(buffer, offset, sizeInBytes);
  }

  /// Construct empty.
  _PrimitiveView.empty();

  /// Get value.
  T get();

  /// Set value.
  void set(T value);

  /// Transfer byte data to the given buffer. Returns the new offset.
  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    var value = get();
    data = new ByteData.view(buffer, offset, sizeInBytes);
    if (copy) {
      set(value);
    }
    return offset + sizeInBytes;
  }
}

class Int8View extends _PrimitiveView<int> {
  static const byteCount = 1;

  Int8View(ByteBuffer buffer, [int offset = 0]) : super.view(buffer, offset);
  Int8View.empty() : super.empty();
  Int8View.value(int value)
      : super.view(new Int8List.fromList([value]).buffer, 0);

  int get sizeInBytes => byteCount;
  int get() => data.getInt8(0);
  void set(int value) => data.setInt8(0, value);
}

class Uint8View extends _PrimitiveView<int> {
  static const byteCount = 1;

  Uint8View(ByteBuffer buffer, [int offset = 0]) : super.view(buffer, offset);
  Uint8View.empty() : super.empty();
  Uint8View.value(int value)
      : super.view(new Uint8List.fromList([value]).buffer, 0);

  int get sizeInBytes => byteCount;
  int get() => data.getUint16(0);
  void set(int value) => data.setUint8(0, value);
}

class Int16View extends _PrimitiveView<int> {
  static const byteCount = 2;

  Int16View(ByteBuffer buffer, [int offset = 0]) : super.view(buffer, offset);
  Int16View.empty() : super.empty();
  Int16View.value(int value)
      : super.view(new Int16List.fromList([value]).buffer, 0);

  int get sizeInBytes => byteCount;
  int get() => data.getInt16(0);
  void set(int value) => data.setInt16(0, value);
}

class Uint16View extends _PrimitiveView<int> {
  static const byteCount = 2;

  Uint16View(ByteBuffer buffer, [int offset = 0]) : super.view(buffer, offset);
  Uint16View.empty() : super.empty();
  Uint16View.value(int value)
      : super.view(new Uint16List.fromList([value]).buffer, 0);

  int get sizeInBytes => byteCount;
  int get() => data.getUint16(0);
  void set(int value) => data.setUint16(0, value);
}

class Int32View extends _PrimitiveView<int> {
  static const byteCount = 4;

  Int32View(ByteBuffer buffer, [int offset = 0]) : super.view(buffer, offset);
  Int32View.empty() : super.empty();
  Int32View.value(int value)
      : super.view(new Int32List.fromList([value]).buffer, 0);

  int get sizeInBytes => byteCount;
  int get() => data.getInt32(0);
  void set(int value) => data.setInt32(0, value);
}

class Uint32View extends _PrimitiveView<int> {
  static const byteCount = 4;

  Uint32View(ByteBuffer buffer, [int offset = 0]) : super.view(buffer, offset);
  Uint32View.empty() : super.empty();
  Uint32View.value(int value)
      : super.view(new Uint32List.fromList([value]).buffer, 0);

  int get sizeInBytes => byteCount;
  int get() => data.getUint32(0);
  void set(int value) => data.setUint32(0, value);
}

class Float32View extends _PrimitiveView<double> {
  static const byteCount = 4;

  Float32View(ByteBuffer buffer, [int offset = 0]) : super.view(buffer, offset);
  Float32View.empty() : super.empty();
  Float32View.value(double value)
      : super.view(new Float32List.fromList([value]).buffer, 0);

  int get sizeInBytes => byteCount;
  double get() => data.getFloat32(0);
  void set(double value) => data.setFloat32(0, value);
}

// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.views;

/// View for a single 32bit floating point value
class Float32View implements Transferrable {
  static const byteCount = 4;
  Float32List view;

  Float32View(ByteBuffer buffer, [int offset = 0])
      : view = new Float32List.view(buffer, offset, 1);
  factory Float32View.value(double value) =>
      new Float32View(new Float32List.fromList([value]).buffer);

  int get sizeInBytes => byteCount;
  double get() => view[0];
  void set(double value) {
    view[0] = value;
  }

  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    var value = view[0];
    view = new Float32List.view(buffer, offset, 1);
    if (copy) {
      view[0] = value;
    }
    return offset + view.lengthInBytes;
  }
}

/// View for a single 32bit integer value
class Uint32View implements Transferrable {
  static const byteCount = 4;
  Uint32List view;

  Uint32View(ByteBuffer buffer, [int offset = 0])
      : view = new Uint32List.view(buffer, offset, 1);
  factory Uint32View.value(int value) =>
      new Uint32View(new Uint32List.fromList([value]).buffer);

  int get sizeInBytes => byteCount;
  int get() => view[0];
  void set(int value) {
    view[0] = value;
  }

  int transfer(ByteBuffer buffer, int offset, [bool copy = true]) {
    var value = view[0];
    view = new Uint32List.view(buffer, offset, 1);
    if (copy) {
      view[0] = value;
    }
    return offset + view.lengthInBytes;
  }
}

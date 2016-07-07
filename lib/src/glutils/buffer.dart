// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.glutils;

/// Base for the buffer utility
abstract class _GlBuffer<D extends TypedData, U> {
  /// Rendering context
  final gl.RenderingContext _ctx;

  /// Number of stored vertices
  int _size = 0;

  /// Buffer data type
  final int _type;

  /// Buffer usage type
  final int _usage;

  /// Buffer target
  final int _target;

  /// All linked attributes
  final List<Tuple4<String, int, int, int>> _attribs =
      new List<Tuple4<String, int, int, int>>();

  /// Coordinates buffer
  final gl.Buffer buffer;

  _GlBuffer(gl.RenderingContext ctx, this._type,
      [this._usage = gl.STATIC_DRAW, this._target = gl.ARRAY_BUFFER])
      : _ctx = ctx,
        buffer = ctx.createBuffer();

  /// Bind the buffer.
  void bind() {
    _ctx.bindBuffer(_target, buffer);
  }

  /// Update buffer data.
  void update(U data);

  /// Substitute buffer data
  void sub(D data, [int offset = 0]) {
    bind();
    _ctx.bufferSubData(_target, offset, data);
  }

  /// Allocate buffer with the given data
  void alloc(D data) {
    bind();
    _ctx.bufferData(_target, data, _usage);
  }

  /// Link all attributes.
  void linkAll(GlShader shaderProgram) {
    bind();
    for (var attrib in _attribs) {
      _ctx.vertexAttribPointer(shaderProgram.attributes[attrib.item1],
          attrib.item2, _type, false, attrib.item3, attrib.item4);
    }
  }
}

/// Buffer for directly storing typed data
class GlBuffer<D extends TypedData> extends _GlBuffer<D, D> {
  GlBuffer(gl.RenderingContext ctx, int type,
      {int usage: gl.STATIC_DRAW, int target: gl.ARRAY_BUFFER})
      : super(ctx, type, usage, target);

  void update(D data) {
    if (data.lengthInBytes == _size) {
      // Substitute data.
      sub(data);
    } else {
      // Reallocate buffer.
      _size = data.lengthInBytes;
      alloc(data);
    }
  }

  /// Add attribute link.
  void link(String attribute, [int stride = 0, int offset = 0, int size = 1]) {
    _attribs.add(
        new Tuple4<String, int, int, int>(attribute, size, stride, offset));
  }
}

/// Buffer for float32 data
class GlFloat32Buffer extends GlBuffer<Float32List> {
  GlFloat32Buffer(gl.RenderingContext ctx,
      {int usage: gl.STATIC_DRAW, int target: gl.ARRAY_BUFFER})
      : super(ctx, gl.FLOAT, usage: usage, target: target);
}

/// Buffer for element indices
class GlIndexBuffer extends GlBuffer<Uint16List> {
  /// Type used for element index buffers.
  static const indexBufferType = gl.ELEMENT_ARRAY_BUFFER;

  GlIndexBuffer(gl.RenderingContext ctx, [int usage = gl.STATIC_DRAW])
      : super(ctx, gl.UNSIGNED_SHORT, usage: usage, target: indexBufferType);
}

/// Buffer for storing vector lists
class GlVectorBuffer<L extends VectorList> extends _GlBuffer<Float32List, L> {
  /// Floats per vertex (vector size)
  final int vectorSize;

  GlVectorBuffer(gl.RenderingContext ctx, this.vectorSize,
      [int usage = gl.STATIC_DRAW])
      : super(ctx, gl.FLOAT, usage, gl.ARRAY_BUFFER);

  void update(L data) {
    if (data.length == _size) {
      // Substitute data.
      sub(data.buffer);
    } else {
      // Reallocate buffer.
      _size = data.length;
      alloc(data.buffer);
    }
  }

  /// Add attribute link.
  void link(String attribute, [int stride = 0, int offset = 0]) {
    _attribs.add(new Tuple4<String, int, int, int>(
        attribute, vectorSize, stride, offset));
  }
}

class GlVector3Buffer extends GlVectorBuffer<Vector3List> {
  GlVector3Buffer(gl.RenderingContext ctx, [int usage = gl.STATIC_DRAW])
      : super(ctx, 3, usage);
}

class GlVector4Buffer extends GlVectorBuffer<Vector4List> {
  GlVector4Buffer(gl.RenderingContext ctx, [int usage = gl.STATIC_DRAW])
      : super(ctx, 4, usage);
}

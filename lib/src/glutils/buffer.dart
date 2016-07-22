// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.glutils;

/// Link between buffer and shader attribute
class AttribPointer {
  /// Attribute label
  final String attrib;

  /// Attribute type, element size, buffer stride and offset.
  final int type, size, stride, offset;

  AttribPointer(this.attrib, this.type, this.size, this.stride, this.offset);
}

/// Base for the buffer utility
abstract class _GlBuffer<D extends List> {
  /// Rendering context
  final gl.RenderingContext _ctx;

  /// Number of stored elements
  int size = 0;

  /// Buffer usage type
  final int _usage;

  /// Buffer target
  final int _target;

  /// All linked attributes
  final List<AttribPointer> _attribs = new List<AttribPointer>();

  /// Coordinates buffer
  final gl.Buffer buffer;

  _GlBuffer(gl.RenderingContext ctx,
      [this._usage = gl.STATIC_DRAW, this._target = gl.ARRAY_BUFFER])
      : _ctx = ctx,
        buffer = ctx.createBuffer();

  /// Bind the buffer.
  void bind() {
    _ctx.bindBuffer(_target, buffer);
  }

  /// Update buffer data.
  void rawUpdate(D data) {
    if (data.length == size) {
      // Substitute data.
      sub(data);
    } else {
      // Reallocate buffer.
      size = data.length;
      alloc(data);
    }
  }

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
    for (final ptr in _attribs) {
      _ctx.vertexAttribPointer(shaderProgram.attributes[ptr.attrib], ptr.size,
          ptr.type, false, ptr.stride, ptr.offset);
    }
  }
}

/// Buffer for directly storing typed data
class GlBuffer<D extends List> extends _GlBuffer<D> {
  GlBuffer(gl.RenderingContext ctx,
      {int usage: gl.STATIC_DRAW, int target: gl.ARRAY_BUFFER})
      : super(ctx, usage, target);

  void update(D data) => rawUpdate(data);

  /// Add attribute link.
  void link(String attribute, int type,
      [int size = 1, int stride = 0, int offset = 0]) {
    _attribs.add(new AttribPointer(attribute, type, size, stride, offset));
  }
}

/// Buffer for element indices
class GlIndexBuffer extends GlBuffer<Uint16List> {
  /// Type used for element index buffers.
  static const indexBufferType = gl.UNSIGNED_SHORT;

  GlIndexBuffer(gl.RenderingContext ctx, [int usage = gl.STATIC_DRAW])
      : super(ctx, usage: usage, target: gl.ELEMENT_ARRAY_BUFFER);
}

/// Buffer for storing vector lists
class GlVectorBuffer<L extends VectorList> extends _GlBuffer<Float32List> {
  /// Floats per vertex (vector size)
  final int vectorSize;

  GlVectorBuffer(gl.RenderingContext ctx, this.vectorSize,
      [int usage = gl.STATIC_DRAW])
      : super(ctx, usage, gl.ARRAY_BUFFER);

  void update(L data) => rawUpdate(data.buffer);

  /// Add attribute link.
  void link(String attribute, [int stride = 0, int offset = 0]) {
    _attribs.add(
        new AttribPointer(attribute, gl.FLOAT, vectorSize, stride, offset));
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

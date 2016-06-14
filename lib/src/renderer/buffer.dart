// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium_webgl_renderer;

/// Wrapper for a GL vertex and color buffer.
class _Buffer {
  /// Current number of stored vertices.
  int _size;

  /// Current vertex buffer data type.
  int _vertexType;

  /// Vertex buffer
  final gl.Buffer v;

  /// Color buffer
  final gl.Buffer c;

  /// Constructor
  _Buffer(gl.RenderingContext glCtx)
      : _size = 0,
        _vertexType = gl.FLOAT,
        v = glCtx.createBuffer(),
        c = glCtx.createBuffer();

  /// Update buffer data
  ///
  /// The vertex list uses 32bit floats and the color buffer uses unsigned 8bit
  /// integers (unsigned byte).
  void updateFloat32(
      gl.RenderingContext _gl, Float32List vertices, Uint8List colors) {
    _update(_gl, vertices, gl.FLOAT, (vertices.length / 3).floor(), colors);
  }

  /// Update buffer data
  ///
  /// The vertex list uses unsigned 16bit integers (unsigned short) and the
  /// color buffer uses unsigned 8bit integers (unsigned byte).
  void updateUint16(
      gl.RenderingContext _gl, Uint16List vertices, Uint8List colors) {
    _update(_gl, vertices, gl.UNSIGNED_SHORT, (vertices.length / 3).floor(),
        colors);
  }

  /// Internal generic buffer update.
  void _update(gl.RenderingContext _gl, TypedData vertices, int vertexType,
      int verticesLength, Uint8List colors) {
    if (colors.length / 4 == verticesLength) {
      if (verticesLength == _size && _vertexType == vertexType) {
        // Substitute data.
        _bufferSub(_gl, v, vertices);
        _bufferSub(_gl, c, colors);
      } else {
        // Reallocate buffer.
        _size = verticesLength;
        _vertexType = vertexType;
        _reallocateBuffer(_gl, v, vertices);
        _reallocateBuffer(_gl, c, colors);
      }
    } else {
      throw new ArgumentError('color and vertices data length do not match');
    }
  }

  /// Internal function for [_update].
  void _bufferSub(gl.RenderingContext _gl, gl.Buffer buffer, TypedData data) {
    _gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    _gl.bufferSubData(gl.ARRAY_BUFFER, 0, data);
  }

  /// Internal function for [_update].
  void _reallocateBuffer(
      gl.RenderingContext _gl, gl.Buffer buffer, TypedData data) {
    _gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    _gl.bufferData(gl.ARRAY_BUFFER, data, gl.DYNAMIC_DRAW);
  }

  /// Draw this buffer as the specified type.
  void draw(gl.RenderingContext _gl, int shaderVertexPosition,
      int shaderVertexColor, int mode,
      [int offset = 0, int length = -1]) {
    // Bind particle positions.
    _gl.bindBuffer(gl.ARRAY_BUFFER, v);
    _gl.vertexAttribPointer(shaderVertexPosition, 3, _vertexType, false, 0, 0);

    // Bind particle colors.
    _gl.bindBuffer(gl.ARRAY_BUFFER, c);
    _gl.vertexAttribPointer(shaderVertexColor, 4, gl.UNSIGNED_BYTE, true, 0, 0);

    // Draw particles.
    var l = length != -1 ? length : _size;
    _gl.drawArrays(mode, offset, l);
  }
}

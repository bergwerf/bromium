// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.glutils;

/// Helper for managing objects
class GlObject {
  /// Transformation matrix uniform label
  static const uViewMatrix = 'uViewMatrix';

  /// Rendering context
  gl.RenderingContext _ctx;

  /// Transformation matrix for this object
  Matrix4 transform;

  /// Shader program used to render this object
  GlShader shaderProgram;

  /// Element index buffer
  GlIndexBuffer indexBuffer;

  /// All object data buffers
  List<_GlBuffer> buffers = new List<_GlBuffer>();

  GlObject(this._ctx);

  /// Constuct from some basic data.
  GlObject.from(this._ctx, this.shaderProgram, Vector3List positions,
      Vector4List colors, Uint16List elementIndices) {
    indexBuffer = new GlIndexBuffer(_ctx)..update(elementIndices);
    buffers.add(new GlVector3Buffer(_ctx)
      ..update(positions)
      ..link(shaderProgram.positionAttrib));

    // Colors are omitted if the shader does not support them.
    if (shaderProgram.colorAttrib != null) {
      buffers.add(new GlVector4Buffer(_ctx)
        ..update(colors)
        ..link(shaderProgram.colorAttrib));
    }
  }

  /// Prepare for drawing.
  void _prepare() {
    shaderProgram.use();

    // Set uniform view matrix.
    _ctx.uniformMatrix4fv(shaderProgram.uViewMatrix, false, transform.storage);

    // Link all buffers.
    for (final buffer in buffers) {
      buffer.linkAll(shaderProgram);
    }
  }

  /// Draw this object using [gl.drawArrays].
  void drawArrays(int mode, int length, [int offset = 0]) {
    _prepare();
    _ctx.drawArrays(mode, offset, length);
  }

  /// Draw this object using [gl.drawElements].
  void drawElements(int mode, [int length = -1, int offset = 0]) {
    _prepare();
    indexBuffer.linkAll(shaderProgram);
    length = length == -1 ? indexBuffer.size : length;
    _ctx.drawElements(mode, length, GlIndexBuffer.indexBufferType, offset);
  }

  /// Draw instanced using an ANGLE extension.
  void drawElementsInstanced(int mode, int count, Map<String, int> divisors,
      [int length = -1, int offset = 0]) {
    _prepare();
    indexBuffer.linkAll(shaderProgram);
    length = length == -1 ? indexBuffer.size : length;

    // Get ANGLE extension.
    gl.AngleInstancedArrays ext = _ctx.getExtension('ANGLE_instanced_arrays');

    // Load divisors.
    divisors.forEach((String attrib, int divisor) {
      ext.vertexAttribDivisorAngle(shaderProgram.attributes[attrib], divisor);
    });

    ext.drawElementsInstancedAngle(
        mode, length, GlIndexBuffer.indexBufferType, offset, count);
  }
}

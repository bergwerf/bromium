// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium_webgl_renderer;

/// Shader helper
class Shader {
  /// Vertex shader
  final String vertexShader;

  /// Fragment shader
  final String fragmentShader;

  /// Last compiled shader program
  gl.Program _shaderProgram;

  /// Attribute names
  final List<String> _attributes;

  /// Attributes mapped to their GL index.
  Map<String, int> attributes;

  /// Uniform names
  final List<String> _uniforms;

  /// Uniforms mapped to their gl.UniformLocation
  Map<String, gl.UniformLocation> uniforms;

  /// Constructor
  Shader(
      this.vertexShader, this.fragmentShader, this._attributes, this._uniforms);

  /// Compile shader in the given GL context.
  void compile(gl.RenderingContext glCtx) {
    // Vertex shader compilation
    gl.Shader vs = glCtx.createShader(gl.RenderingContext.VERTEX_SHADER);
    glCtx.shaderSource(vs, vertexShader);
    glCtx.compileShader(vs);

    // Fragment shader compilation
    gl.Shader fs = glCtx.createShader(gl.RenderingContext.FRAGMENT_SHADER);
    glCtx.shaderSource(fs, fragmentShader);
    glCtx.compileShader(fs);

    // Attach shaders to a WebGL program.
    _shaderProgram = glCtx.createProgram();
    glCtx.attachShader(_shaderProgram, vs);
    glCtx.attachShader(_shaderProgram, fs);
    glCtx.linkProgram(_shaderProgram);
    glCtx.useProgram(_shaderProgram);

    // Check if shaders were compiled properly. This is probably the most
    // painful part since there's no way to "debug" shader compilation.
    if (!glCtx.getShaderParameter(vs, gl.RenderingContext.COMPILE_STATUS)) {
      throw new Exception(glCtx.getShaderInfoLog(vs));
    }
    if (!glCtx.getShaderParameter(fs, gl.RenderingContext.COMPILE_STATUS)) {
      throw new Exception(glCtx.getShaderInfoLog(fs));
    }
    if (!glCtx.getProgramParameter(
        _shaderProgram, gl.RenderingContext.LINK_STATUS)) {
      throw new Exception(glCtx.getProgramInfoLog(_shaderProgram));
    }

    // Link shader attributes.
    attributes = new Map<String, int>();
    _attributes.forEach((String attrib) {
      attributes[attrib] = glCtx.getAttribLocation(_shaderProgram, attrib);
      glCtx.enableVertexAttribArray(attributes[attrib]);
    });

    // Link shader uniforms.
    uniforms = new Map<String, gl.UniformLocation>();
    _uniforms.forEach((String uniform) {
      uniforms[uniform] = glCtx.getUniformLocation(_shaderProgram, uniform);
    });
  }

  /// Use this shader.
  void use(gl.RenderingContext glCtx) {}
}

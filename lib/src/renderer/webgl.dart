// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium_webgl_renderer;

class BromiumWebGLRenderer {
  /// Backend engine that is used to retrieve the particle information.
  BromiumEngine _engine;

  /// Output canvas
  CanvasElement _canvas;

  /// Vertex and color buffers for the particle system.
  _Buffer _particleSystem;

  // Vertex and color buffers for each membrane (faces and wireframe).
  List<Tuple2<_Buffer, _Buffer>> _membranes =
      new List<Tuple2<_Buffer, _Buffer>>();

  /// WebGL context
  gl.RenderingContext _gl;

  /// Main shader program
  gl.Program _shaderProgram;

  /// Viewport dimensions
  int _viewportWidth, _viewportHeight;

  // Shader attributes
  int _aVertexPosition;
  int _aVertexColor;
  gl.UniformLocation _uViewMatrix;

  /// View matrix
  Matrix4 _viewMatrix;

  /// Scene center
  Vector3 _center;

  /// Trackball
  _Trackball _trackball;

  /// Do not call [_requestFrame] in the next [render] cycle.
  bool _blockRendering = false;

  /// Update simulation data in render cycle?
  bool runSimulation = true;

  /// Use isolates for simulation computations?
  bool runInIsolate = true;

  /// Constructor
  BromiumWebGLRenderer(this._engine, this._canvas) {
    _viewportWidth = _canvas.width;
    _viewportHeight = _canvas.height;
    _gl = _canvas.getContext('webgl');

    // Set some WebGL settings.
    _gl.clearColor(0.0, 0.0, 0.0, 1.0);
    _gl.enable(gl.CULL_FACE);
    _gl.enable(gl.DEPTH_TEST);
    _gl.enable(gl.BLEND);
    _gl.cullFace(gl.FRONT);
    _gl.depthFunc(gl.LESS);
    _gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    // Load shaders.
    _initShaders();

    // Setup buffer for the particle system.
    _particleSystem = new _Buffer(_gl);

    // Setup trackball.
    _trackball = new _Trackball(_canvas, 1.1);
  }

  /// Resest the camera position and zooming.
  void resetCamera(Vector3 center, double z, double depth) {
    _trackball.z = -2.0 * z;
    _center = center;
    _viewMatrix = makePerspectiveMatrix(
        radians(45.0),
        _viewportWidth / _viewportHeight,
        _engine.sim.info.space.utov(0.01),
        depth);
  }

  /// Reload membrane data from the computation engine.
  void reloadMembranes() {
    for (var m = 0; m < _engine.sim.buffer.nMembranes; m++) {
      var faceBuffer = new _Buffer(_gl);
      var wireBuffer = new _Buffer(_gl);

      var dims = _engine.sim.buffer.getMembraneDimensions(m);
      var faceVerts = computeDomainPolygon(_engine.sim.info.membranes[m], dims);
      var wireVerts =
          computeDomainWireframe(_engine.sim.info.membranes[m], dims);

      var faceColors = new Uint8List((faceVerts.length / 3).ceil() * 4);
      var wireColors = new Uint8List((wireVerts.length / 3).ceil() * 4);

      for (var i = 0; i < faceColors.length; i += 4) {
        faceColors[i + 0] = 255;
        faceColors[i + 1] = 255;
        faceColors[i + 2] = 255;
        faceColors[i + 3] =
            _engine.sim.info.membranes[m] == DomainType.cuboid ? 0 : 64;
      }

      for (var i = 0; i < wireColors.length; i += 4) {
        wireColors[i + 0] = 255;
        wireColors[i + 1] = 255;
        wireColors[i + 2] = 255;
        wireColors[i + 3] = 255;
      }

      faceBuffer.updateFloat32(_gl, faceVerts, faceColors);
      wireBuffer.updateFloat32(_gl, wireVerts, wireColors);
      _membranes.add(new Tuple2<_Buffer, _Buffer>(faceBuffer, wireBuffer));
    }
  }

  /// Load shader program.
  void _initShaders() {
    // Vertex shader
    String vsSource = '''
attribute vec3 aVertexPosition;
attribute vec4 aVertexColor;

uniform mat4 uViewMatrix;

varying vec4 vColor;

void main(void) {
  gl_PointSize = 1.5;
  gl_Position = uViewMatrix * vec4(aVertexPosition, 1.0);
  vColor = aVertexColor;
}
''';

    // Fragment shader
    String fsSource = '''
precision mediump float;
varying vec4 vColor;
void main(void) {
  gl_FragColor = vColor;
}
''';

    // Vertex shader compilation
    gl.Shader vs = _gl.createShader(gl.RenderingContext.VERTEX_SHADER);
    _gl.shaderSource(vs, vsSource);
    _gl.compileShader(vs);

    // Fragment shader compilation
    gl.Shader fs = _gl.createShader(gl.RenderingContext.FRAGMENT_SHADER);
    _gl.shaderSource(fs, fsSource);
    _gl.compileShader(fs);

    // Attach shaders to a WebGL program.
    _shaderProgram = _gl.createProgram();
    _gl.attachShader(_shaderProgram, vs);
    _gl.attachShader(_shaderProgram, fs);
    _gl.linkProgram(_shaderProgram);
    _gl.useProgram(_shaderProgram);

    // Check if shaders were compiled properly. This is probably the most
    // painful part since there's no way to "debug" shader compilation.
    if (!_gl.getShaderParameter(vs, gl.RenderingContext.COMPILE_STATUS)) {
      print(_gl.getShaderInfoLog(vs));
    }
    if (!_gl.getShaderParameter(fs, gl.RenderingContext.COMPILE_STATUS)) {
      print(_gl.getShaderInfoLog(fs));
    }
    if (!_gl.getProgramParameter(
        _shaderProgram, gl.RenderingContext.LINK_STATUS)) {
      print(_gl.getProgramInfoLog(_shaderProgram));
    }

    // Link shader attributes.
    _aVertexPosition = _gl.getAttribLocation(_shaderProgram, "aVertexPosition");
    _gl.enableVertexAttribArray(_aVertexPosition);
    _aVertexColor = _gl.getAttribLocation(_shaderProgram, "aVertexColor");
    _gl.enableVertexAttribArray(_aVertexColor);
    _uViewMatrix = _gl.getUniformLocation(_shaderProgram, "uViewMatrix");
  }

  /// Perform one simulation cycle and render a single frame.
  void render(double time) {
    // Update particle system.
    _particleSystem.updateUint16(
        _gl, _engine.sim.buffer.pCoords, _engine.sim.buffer.pColor);

    if (runSimulation && !runInIsolate) {
      // Run a simulation cycle on the main thread.
      _engine.step();
    }

    // Clear view.
    _gl.viewport(0, 0, _viewportWidth, _viewportHeight);
    _gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    // Transform view matrix.
    var viewMatrix = _viewMatrix.clone();
    viewMatrix.translate(0.0, 0.0, _trackball.z);
    viewMatrix.multiply(_trackball.rotationMatrix);
    viewMatrix.translate(_center.clone()..scale(-1.0));

    // Apply view matrix.
    Float32List viewMatrixCpy = new Float32List(16);
    viewMatrix.copyIntoArray(viewMatrixCpy);
    _gl.uniformMatrix4fv(_uViewMatrix, false, viewMatrixCpy);

    // Draw particles.
    _particleSystem.draw(_gl, _aVertexPosition, _aVertexColor, gl.POINTS, 0,
        _engine.sim.buffer.activeParticleCount);

    // Draw membranes.
    _membranes.forEach((Tuple2<_Buffer, _Buffer> b) {
      b.item1.draw(_gl, _aVertexPosition, _aVertexColor, gl.TRIANGLES);
      _gl.disable(gl.DEPTH_TEST);
      b.item2.draw(_gl, _aVertexPosition, _aVertexColor, gl.LINES);
      _gl.enable(gl.DEPTH_TEST);
    });

    // Schedule next frame.
    if (!_blockRendering) {
      this._requestFrame();
    }
  }

  /// Start rendering
  void start() {
    _blockRendering = false;
    this._requestFrame();
  }

  /// Stop rendering
  void stop() {
    _blockRendering = true;
  }

  /// Schedule a new render cycle.
  void _requestFrame() {
    window.requestAnimationFrame((num time) {
      this.render(time);
    });
  }
}

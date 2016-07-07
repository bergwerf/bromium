// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.glutils;

/// Utility class for creating 3D views
abstract class GlCanvas {
  /// Default field of view angle
  static const defaultFov = 30.0;

  /// Multiplier constant used for focussing on a bounding box
  static const focusMultiplier = 2.0;

  /// Output canvas
  CanvasElement canvas;

  /// Viewport dimensions
  int _viewportWidth, _viewportHeight;

  /// WebGL context
  gl.RenderingContext ctx;

  /// Projection matrix
  Matrix4 projection;

  /// Trackball
  Trackball trackball;

  /// Scene center
  Vector3 center;

  /// Render controls
  bool _pause = true;

  /// Construct from document ID.
  GlCanvas.fromId(String id, [double fov = defaultFov]) {
    // Get canvas and create WebGL context.
    canvas = document.getElementById(id);
    ctx = canvas.getContext('webgl');

    // Load our default WebGL settings.
    ctx.clearColor(0.0, 0.0, 0.0, 1.0);
    ctx.enable(gl.CULL_FACE);
    ctx.cullFace(gl.FRONT);
    ctx.enable(gl.DEPTH_TEST);
    ctx.depthFunc(gl.LESS);
    ctx.enable(gl.BLEND);
    ctx.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    // Create projection matrix.
    _viewportWidth = canvas.clientWidth;
    _viewportHeight = canvas.clientHeight;
    projection = makePerspectiveMatrix(
        radians(45.0), _viewportWidth / _viewportHeight, 0.01, 1000.0);
  }

  /// Focus the camera on the given bounding box.
  void focus(Aabb3 target) {
    // Compute center.
    center = target.center;

    // Compute distance to target egde and multiply by focusMultiplier for z.
    trackball.z = focusMultiplier * target.min.distanceTo(center);
  }

  /// One draw cycle
  void draw(num time);

  /// Internal draw cycle
  void _draw(num time) {
    // Clear view
    ctx.viewport(0, 0, _viewportWidth, _viewportHeight);
    ctx.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    // Run main draw method.
    draw(time);

    // Schedule next frame.
    if (!_pause) {
      this._scheduleFrame();
    }
  }

  /// Start rendering
  void start() {
    _pause = false;
    this._scheduleFrame();
  }

  /// Pause rendering
  void pause() {
    _pause = true;
  }

  /// Schedule a new render cycle.
  void _scheduleFrame() {
    window.requestAnimationFrame((num time) {
      _draw(time);
    });
  }
}

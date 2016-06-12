// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium_webgl_renderer;

/// Mouse data for user interaction.
class _Mouse {
  /// Zoom value
  double z;

  /// A mouse button is pressed
  bool down = false;

  /// Previous x and y coordinates
  int lastX = 0, lastY = 0;

  /// Rotation matrix applied to WebGL camera.
  Matrix4 rotationMatrix = new Matrix4.identity();

  /// Constructor
  _Mouse(this.z);
}

/// Trackball user control
class _Trackball {
  /// Mouse data
  _Mouse _mouse;

  /// Zoom speed
  double zoomSpeed = 1.1;

  /// Constructor
  _Trackball(CanvasElement canvas, this.zoomSpeed) {
    _mouse = new _Mouse(0.0);

    canvas.onMouseDown.listen((MouseEvent event) {
      _mouse.down = true;
      _mouse.lastX = event.client.x;
      _mouse.lastY = event.client.y;
    });

    canvas.onMouseUp.listen((MouseEvent event) {
      _mouse.down = false;
    });

    canvas.onMouseOut.listen((MouseEvent event) {
      _mouse.down = false;
    });

    canvas.onMouseMove.listen((MouseEvent event) {
      if (!_mouse.down) return;

      // Apply rotation to rotationMatrix.
      var matrix = new Matrix4.identity();
      matrix.rotateY((event.client.x - _mouse.lastX) / 100);
      matrix.rotateX((event.client.y - _mouse.lastY) / 100);
      matrix.multiply(_mouse.rotationMatrix);
      _mouse.rotationMatrix = matrix;

      _mouse.lastX = event.client.x;
      _mouse.lastY = event.client.y;
    });

    canvas.onMouseWheel.listen((WheelEvent event) {
      _mouse.z *= event.deltaY > 0 ? zoomSpeed : (1 / zoomSpeed);
    });
  }

  /// Get rotation matrix from [_mouse].
  Matrix4 get rotationMatrix => _mouse.rotationMatrix;

  /// Get z translation from [_mouse].
  double get z => _mouse.z;

  /// Set z translation of [_mouse].
  set z(double z) => _mouse.z = z;
}

// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.glutils;

/// Mouse data for user interaction.
class _MouseData {
  /// Zoom value
  double z;

  /// A mouse button is pressed
  bool down = false;

  /// Previous x and y coordinates
  int lastX = 0, lastY = 0;

  /// Previous point distance
  double distance = 0.0;

  /// Rotation matrix applied to WebGL camera.
  Matrix4 rotationMatrix = new Matrix4.identity();

  /// Constructor
  _MouseData(this.z);
}

/// Trackball user control
class Trackball {
  /// Mouse data
  _MouseData _mouse;

  /// Zoom speed
  double zoomSpeed = 1.1;

  /// Constructor
  Trackball(CanvasElement canvas, this.zoomSpeed) {
    _mouse = new _MouseData(0.0);

    canvas.onMouseDown.listen((MouseEvent event) {
      onPointerDown(event.client.x, event.client.y);
    });

    canvas.onMouseMove.listen((MouseEvent event) {
      onPointerMove(event.client.x, event.client.y);
    });

    canvas.onTouchStart.listen((TouchEvent event) {
      event.preventDefault();
      final point = event.touches.first.page;
      onPointerDown(point.x, point.y);
    });

    canvas.onTouchMove.listen((TouchEvent event) {
      final point = event.touches.first.page;
      onPointerMove(point.x, point.y);

      // Zooming
      if (event.touches.length > 1) {
        var distance =
            event.touches.first.page.distanceTo(event.touches.last.page);

        if (_mouse.distance > 0) {
          // Apply scaling.
          onZoom(distance / _mouse.distance);
          _mouse.distance = distance;
        }
      }
    });

    canvas.onMouseUp.listen((_) => onPointerAway());
    canvas.onMouseOut.listen((_) => onPointerAway());
    canvas.onTouchLeave.listen(
        (TouchEvent event) => onPointerAway(event.targetTouches.length));
    canvas.onTouchEnd.listen(
        (TouchEvent event) => onPointerAway(event.targetTouches.length));
    canvas.onTouchCancel.listen(
        (TouchEvent event) => onPointerAway(event.targetTouches.length));

    canvas.onMouseWheel.listen((WheelEvent event) {
      onZoom(event.deltaY > 0 ? zoomSpeed : (1 / zoomSpeed));
    });
  }

  /// Get rotation matrix from [_mouse].
  Matrix4 get rotationMatrix => _mouse.rotationMatrix;

  /// Get z translation from [_mouse].
  double get z => _mouse.z;

  /// Set z translation of [_mouse].
  set z(double z) => _mouse.z = z;

  void onPointerDown(num x, num y) {
    _mouse.down = true;
    _mouse.lastX = x;
    _mouse.lastY = y;
  }

  void onPointerMove(num x, num y) {
    if (!_mouse.down) return;

    // Apply rotation to rotationMatrix.
    var matrix = new Matrix4.identity();
    matrix.rotateY((x - _mouse.lastX) / 100);
    matrix.rotateX((y - _mouse.lastY) / 100);
    matrix.multiply(_mouse.rotationMatrix);
    _mouse.rotationMatrix = matrix;

    _mouse.lastX = x;
    _mouse.lastY = y;
  }

  void onPointerAway([int nPointers = 0]) {
    _mouse.down = false;

    if (nPointers > 1) {
      _mouse.distance = 0.0;
    }
  }

  void onZoom(num factor) {
    _mouse.z *= factor;
  }
}

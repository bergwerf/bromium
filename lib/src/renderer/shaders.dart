// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium_webgl_renderer;

/// Vertex shader
const _vsSource = '''
attribute vec3 aVertexPosition;
attribute vec4 aVertexColor;

uniform mat4 uViewMatrix, uRotationMatrix;
uniform float uZoom, uTranslateX, uTranslateY, uTranslateZ;
uniform float uScaleX, uScaleY, uScaleZ;

varying vec4 vColor;

void main(void) {
  mat4 zoomMatrix = mat4(
    vec4(1.0, 0.0, 0.0, 0.0),
    vec4(0.0, 1.0, 0.0, 0.0),
    vec4(0.0, 0.0, 1.0, 0.0),
    vec4(0.0, 0.0, uZoom, 1.0)
  );

  mat4 translateMatrix = mat4(
    vec4(1.0, 0.0, 0.0, 0.0),
    vec4(0.0, 1.0, 0.0, 0.0),
    vec4(0.0, 0.0, 1.0, 0.0),
    vec4(uTranslateX, uTranslateY, uTranslateZ, 1.0)
  );

  mat4 scaleMatrix = mat4(
    vec4(uScaleX, 0.0, 0.0, 0.0),
    vec4(0.0, uScaleY, 0.0, 0.0),
    vec4(0.0, 0.0, uScaleZ, 0.0),
    vec4(1.0, 1.0, 1.0, 1.0)
  );

  gl_PointSize = 1.5;
  gl_Position = uViewMatrix
    * zoomMatrix
    * uRotationMatrix
    * scaleMatrix
    * translateMatrix
    * vec4(aVertexPosition, 1.0);

  vColor = aVertexColor;
}
''';

/// Fragment shader
const _fsSource = '''
precision mediump float;

varying vec4 vColor;

void main(void) {
  gl_FragColor = vColor;
}
''';

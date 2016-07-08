// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.renderer;

const _membraneVertexShaderSrc = '''
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

const _membraneFragmentShaderSrc = '''
precision mediump float;

varying vec4 vColor;

void main(void) {
  gl_FragColor = vColor;
}
''';

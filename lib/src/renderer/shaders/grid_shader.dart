// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.renderer;

const _gridVertexShaderSrc = '''
attribute vec3 aVertexPosition;

uniform mat4 uViewMatrix;

varying vec3 vertex;

void main(void) {
  gl_PointSize = 1.5;
  gl_Position = uViewMatrix * vec4(aVertexPosition, 1.0);

  vertex = aVertexPosition;
}
''';

// This is a grid shader, see: http://madebyevan.com/shaders/grid/.
const _gridFragmentShaderSrc = '''
// License: CC0 (http://creativecommons.org/publicdomain/zero/1.0/)
#extension GL_OES_standard_derivatives : enable

precision mediump float;

uniform vec4 uLineColor;

varying vec3 vertex;

void main() {
  // Pick a coordinate to visualize in a grid
  vec2 coord = vertex.xz * 10.0;

  // Compute anti-aliased world-space grid lines
  vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
  float line = min(grid.x, grid.y);

  // Just visualize the grid lines directly
  gl_FragColor = uLineColor * vec4(1.0 - min(line, 1.0));
}
''';

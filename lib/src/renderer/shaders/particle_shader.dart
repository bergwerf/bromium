// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.renderer;

/// Particle vertex shader generator
String _generateParticleShader(int particleTypeCount) => '''
attribute vec3 particlePosition;
attribute uint particleType;

uniform vec4 uTypeColors[$particleTypeCount];
uniform float uTypeRadii[$particleTypeCount];
uniform mat4 uViewMatrix;

varying vec4 vColor;

void main(void) {
  gl_PointSize = uTypeRadii[particleType];
  gl_Position = uMatrix * vec4(aVertexPosition, 1.0);

  vColor = uTypeColors[particleType];
}
''';

const _particleVertexShaderSrc = '''
attribute vec3 aParticlePosition;
attribute vec3 aParticleColor;

uniform mat4 uViewMatrix;

varying vec4 vColor;

void main(void) {
  gl_PointSize = 1.5;
  gl_Position = uViewMatrix * vec4(aParticlePosition, 1.0);

  vColor = vec4(aParticleColor, 1.0);
}
''';

const _particleFragmentShaderSrc = '''
precision mediump float;

varying vec4 vColor;

void main(void) {
  gl_FragColor = vColor;
}
''';

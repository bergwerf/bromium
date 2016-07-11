// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.renderer;

const _particleVertexShaderSrc = '''
attribute vec2 aImposterPosition;
attribute vec3 aParticlePosition;
attribute vec3 aParticleColor;
attribute float aParticleRadius;

uniform mat4 uViewMatrix;
uniform float uViewportRatio;

varying vec3 sphereColor;
varying vec3 spherePosition;
varying vec2 impostorPosition;

void main(void) {
  vec2 imp = vec2(aImposterPosition.x, aImposterPosition.y * uViewportRatio);
  vec4 position = uViewMatrix * vec4(aParticlePosition, 1.0);

  sphereColor = aParticleColor;
  impostorPosition = aImposterPosition;
  spherePosition = position.xyz;

  gl_Position = position + aParticleRadius * vec4(imp, 0.0, 0.0);
}
''';

const _particleFragmentShaderSrc = '''
#extension GL_OES_standard_derivatives : enable

precision mediump float;

//uniform highp mat4 uViewMatrix;
uniform vec3 uLightPosition;

varying vec3 sphereColor;
varying vec3 spherePosition;
varying vec2 impostorPosition;

void main()
{
    float dist = length(impostorPosition);

    if (dist > 1.0) {
      discard;
    }

    // Lighting
    // 1. Project light on sphere
    // 2. Compute radial gradient

    // With view matrix (light spot moves when rotating).
    //vec4 light = uViewMatrix * vec4(uLightPosition, 1.0);
    //light = light - vec4(spherePosition, 0.0);
    //light = light / length(light.xyz);

    // Without view matrix (light spots are fixed).
    vec3 light = uLightPosition - spherePosition;
    light = light / length(light);

    // Compute distance from radial center to fragment coordinate.
    float rdist = length(impostorPosition - light.xy);

    // Apply radial gradients.
    vec3 color = sphereColor;
    color = mix(vec3(1.0, 1.0, 1.0), color, 0.5 + 0.5 * smoothstep(0.0, 1.0, rdist));
    color = mix(color, vec3(0.0, 0.0, 0.0), smoothstep(0.6, 2.0, rdist));
    color = mix(color, vec3(0.0, 0.0, 0.0), smoothstep(1.0, 1.5, rdist));

    gl_FragColor = vec4(color, 1.0);

    // Anti-aliased circles.
    //float delta = fwidth(dist);
    //float alpha = smoothstep(1.0, 1.0 - delta, dist);
    //gl_FragColor = mix(vec4(0.0, 0.0, 0.0, 0.0), vec4(sphereColor, 1.0), alpha);
}
''';

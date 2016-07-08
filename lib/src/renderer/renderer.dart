// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.renderer;

/// WebGL renderer for the particle system + membranes
class BromiumWebGLRenderer extends GlCanvas {
  /// Backend engine that is used to retrieve the particle information.
  BromiumEngine engine;

  /// Particle system
  GlObject particleSystem;

  /// Particle data
  GlBuffer<Float32List> particleData;

  /// Shaders
  GlShader particleShader, gridShader;

  /// Cube shape for drawing AABB membranes
  GlCube cubeGeometry;

  /// Sphere shape for drawing ellipsoid membranes
  GlSphere sphereGeometry;

  /// Constructor
  BromiumWebGLRenderer(this.engine, CanvasElement canvas)
      : super.fromId(canvas) {
    // Compile particle shader.
    particleShader = new GlShader(
        ctx,
        _particleVertexShaderSrc,
        _particleFragmentShaderSrc,
        ['aParticlePosition', 'aParticleColor'],
        ['uViewMatrix',]);
    particleShader.positionAttrib = 'aParticlePosition';
    particleShader.colorAttrib = 'aParticleColor';
    particleShader.viewMatrix = 'uViewMatrix';
    particleShader.compile();

    // Compile grid shader.
    ctx.getExtension('OES_standard_derivatives');
    gridShader = new GlShader(ctx, _gridVertexShaderSrc, _gridFragmentShaderSrc,
        ['aVertexPosition'], ['uViewMatrix', 'uLineColor']);
    gridShader.positionAttrib = 'aVertexPosition';
    gridShader.viewMatrix = 'uViewMatrix';
    gridShader.compile();

    // Setup cube and sphere geometry.
    cubeGeometry = new GlCube(ctx,
        wireframeColor: new Vector4(0.0, 0.0, 0.0, 1.0),
        surfaceColor: new Vector4(1.0, 1.0, 1.0, 0.1),
        shader: gridShader);
    sphereGeometry = new GlSphere(ctx, 40, 80,
        wireframeColor: new Vector4(0.0, 0.0, 0.0, 1.0),
        surfaceColor: new Vector4(1.0, 1.0, 1.0, 0.3),
        shader: gridShader);

    // Setup particle system.
    particleSystem = new GlObject(ctx);
    particleSystem.shaderProgram = particleShader;
    particleData = new GlBuffer<Float32List>(ctx);
    particleData.link('aParticlePosition', gl.FLOAT, 3, 24, 0);
    particleData.link('aParticleColor', gl.FLOAT, 3, 24, 12);
    particleSystem.buffers.add(particleData);
  }

  void draw(num time, Matrix4 viewMatrix) {
    if (engine.onRenderThread) {
      engine.cycle();
    }

    if (engine.changed) {
      particleData.update(engine.renderBuffer.getParticleData());
    }

    // Transform the particle system using viewMatrix and draw as points.
    particleSystem.transform = viewMatrix;
    particleSystem.drawArrays(
        gl.POINTS, engine.renderBuffer.header.particleCount);

    // Draw all membranes.
    var membranes = engine.renderBuffer.generateMembraneDomains();
    for (var membrane in membranes) {
      if (membrane is AabbDomain) {
        cubeGeometry.transform =
            viewMatrix * GlCube.computeTransform(membrane.data);
        cubeGeometry.draw();
      } else if (membrane is EllipsoidDomain) {
        sphereGeometry.transform = viewMatrix *
            GlSphere.computeTransform(membrane.center, membrane.semiAxes);
        gridShader.use();
        ctx.cullFace(gl.BACK);
        ctx.uniform4fv(gridShader.uniforms['uLineColor'],
            new Vector4(1.0, 1.0, 1.0, 0.3).storage);
        sphereGeometry.draw(drawWireframe: false);
        ctx.cullFace(gl.FRONT);
        ctx.uniform4fv(gridShader.uniforms['uLineColor'],
            new Vector4(1.0, 1.0, 1.0, 1.0).storage);
        sphereGeometry.draw(drawWireframe: false);
      }
    }
  }
}

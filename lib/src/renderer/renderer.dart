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

  /// Particle imposter positions
  GlBuffer<Float32List> imposterPositions;

  /// Shaders
  GlShader particleShader, gridShader;

  /// Cube shape for drawing AABB membranes
  GlCube cubeGeometry;

  /// Sphere shape for drawing ellipsoid membranes
  GlSphere sphereGeometry;

  /// Constructor
  BromiumWebGLRenderer(this.engine, CanvasElement canvas)
      : super.fromId(canvas) {
    // Load shader extensions.
    ctx.getExtension('OES_standard_derivatives');
    //ctx.getExtension('EXT_frag_depth');

    // Compile particle shader.
    particleShader = new GlShader(
        ctx, _particleVertexShaderSrc, _particleFragmentShaderSrc, [
      'aImposterPosition',
      'aParticlePosition',
      'aParticleColor',
      'aParticleRadius'
    ], [
      'uViewMatrix',
      'uViewportRatio',
      'uLightPosition'
    ]);
    particleShader.positionAttrib = 'aParticlePosition';
    particleShader.colorAttrib = 'aParticleColor';
    particleShader.viewMatrix = 'uViewMatrix';
    particleShader.compile();

    // Compile grid shader.
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
    particleData.link('aParticlePosition', gl.FLOAT, 3, 32, 0);
    particleData.link('aParticleColor', gl.FLOAT, 3, 32, 12);
    particleData.link('aParticleRadius', gl.FLOAT, 1, 32, 24);
    particleSystem.buffers.add(particleData);

    // Add particle vertices.
    imposterPositions = new GlBuffer<Float32List>(ctx);
    imposterPositions.link('aImposterPosition', gl.FLOAT, 2);
    imposterPositions.update(
        new Float32List.fromList([1.0, 1.0, 1.0, -1.0, -1.0, -1.0, -1.0, 1.0]));
    particleSystem.buffers.add(imposterPositions);

    // Add particle elements (two triangles).
    particleSystem.indexBuffer = new GlIndexBuffer(ctx);
    particleSystem.indexBuffer
        .update(new Uint16List.fromList([0, 1, 2, 0, 2, 3]));
  }

  /// Update particles buffer.
  void updateParticles() {
    particleData.update(engine.renderBuffer.getParticleData());
  }

  void draw(num time, Matrix4 viewMatrix) {
    if (engine.isRunning) {
      engine.update();
      updateParticles();
    }

    // Transform the particle system using viewMatrix.
    particleSystem.transform = viewMatrix;

    // Set uniforms.
    particleShader.use();
    ctx.uniform1f(particleShader.uniforms['uViewportRatio'],
        viewportWidth / viewportHeight);
    ctx.uniform3fv(particleShader.uniforms['uLightPosition'],
        new Float32List.fromList([3.0, 3.0, 10.0]));

    particleSystem.drawElementsInstanced(
        gl.TRIANGLES,
        engine.renderBuffer.header.particleCount,
        {'aParticlePosition': 1, 'aParticleColor': 1, 'aParticleRadius': 1});

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

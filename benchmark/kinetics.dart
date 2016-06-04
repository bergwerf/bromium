// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'package:color/color.dart';
import 'package:bromium/bromium.dart';
import 'package:vector_math/vector_math.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

/// [BromiumKineticsAlgorithm] benchmarking
class KineticsAlgorithmBenchmark extends BenchmarkBase {
  /// [BromiumEngine] instance to generate particle data.
  BromiumEngine engine;

  /// [BromiumKineticsAlgorithm] function
  final BromiumKineticsAlgorithm fn;

  /// Number of particles to simulate
  final int n;

  /// Constructor
  KineticsAlgorithmBenchmark(String name, this.fn, this.n) : super(name);

  /// Run the kinetics simulation.
  void run() {
    fn(engine.data);
  }

  /// Setup a [BromiumEngine] instance and load some particles.
  void setup() {
    engine = new BromiumEngine();
    engine.addParticle('A', 0.01, RgbColor.namedColors['red']);
    engine.addParticle('B', 0.01, RgbColor.namedColors['blue']);

    // Simulate 10.000 particles.
    engine.allocateParticles([
      new ParticleSet('A', (n / 2).floor(),
          new BoxDomain(new Vector3(.0, .0, .0), new Vector3(1.0, 1.0, 1.0))),
      new ParticleSet('B', (n / 2).floor(),
          new BoxDomain(new Vector3(.0, .0, .0), new Vector3(1.0, 1.0, 1.0)))
    ]);
  }

  /// There is no teardown process (the GC will take care of this).
  void teardown() {}
}

void benchmarkKineticsAlgorithm(String name, BromiumKineticsAlgorithm fn) {
  new KineticsAlgorithmBenchmark('$name; N=100', fn, 100).report();
  new KineticsAlgorithmBenchmark('$name; N=1000', fn, 1000).report();
  new KineticsAlgorithmBenchmark('$name; N=10000', fn, 10000).report();
}

void main() {
  benchmarkKineticsAlgorithm('Nested map', nestedMapKinetics);
  benchmarkKineticsAlgorithm('String map', stringMapKinetics);
  benchmarkKineticsAlgorithm('MPHF map', mphfMapKinetics);
  benchmarkKineticsAlgorithm('AVL tree', avlTreeKinetics);
}

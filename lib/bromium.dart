// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium;

import 'dart:math';
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';
import 'package:color/color.dart';
import 'package:vector_math/vector_math.dart';

// Benchmark helper
part 'src/benchmark.dart';

// Domains library
part 'src/domains/domain.dart';
part 'src/domains/box.dart';
part 'src/domains/ellipsoid.dart';
part 'src/domains/polygons.dart';

// Data structures
part 'src/data/voxels.dart';
part 'src/data/particle_info.dart';
part 'src/data/particle_dict.dart';
part 'src/data/particle_set.dart';
part 'src/data/bind_reaction.dart';
part 'src/data/membrane.dart';
part 'src/data/simulation_info.dart';
part 'src/data/simulation_buffer.dart';
part 'src/data/simulation.dart';

// Kinetics algorithms
part 'src/kinetics/compute_motion.dart';
part 'src/kinetics/reactions/base.dart';
part 'src/kinetics/reactions/intmap.dart';
part 'src/kinetics/reactions/intset.dart';
part 'src/kinetics/reactions/arraysort.dart';

// Computation engine class
part 'src/engine.dart';

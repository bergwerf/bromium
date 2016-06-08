// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium;

import 'dart:math';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';
import 'package:color/color.dart';

// Domains library
part 'src/domains/domain.dart';
part 'src/domains/cuboid.dart';
part 'src/domains/ellipsoid.dart';

// Particle data
part 'src/particles.dart';
part 'src/data.dart';

// Kinetics algorithms
part 'src/kinetics/membrane.dart';
part 'src/kinetics/reactions.dart';
part 'src/kinetics/compute_motion.dart';
part 'src/kinetics/compute_reactions.dart';
part 'src/kinetics/voxel_group.dart';

// Computation engine class
part 'src/engine.dart';

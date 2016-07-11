// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium.kinetics;

import 'dart:math';

import 'package:tuple/tuple.dart';
import 'package:bromium/math.dart';
import 'package:bromium/structs.dart';
import 'package:vector_math/vector_math.dart';

part 'src/kinetics/particle_motion.dart';
part 'src/kinetics/membrane_collisions.dart';
part 'src/kinetics/reactions/base.dart';
part 'src/kinetics/reactions/bit_interleave.dart';
part 'src/kinetics/reactions/fast_voxel.dart';
part 'src/kinetics/reactions/unbind_random.dart';

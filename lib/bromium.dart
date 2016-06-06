// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium;

import 'dart:math';
import 'dart:typed_data';
import 'dart:web_gl' as gl;

import 'package:vector_math/vector_math.dart';
import 'package:color/color.dart';

part 'src/domain.dart';
part 'src/particles.dart';
part 'src/data.dart';
part 'src/kinetics/data.dart';
part 'src/kinetics/compute.dart';
part 'src/engine.dart';

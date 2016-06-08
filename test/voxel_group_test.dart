// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium.test.voxel_group;

import 'dart:math';

import 'package:test/test.dart';
import 'package:bromium/bromium.dart';

void main() {
  test('computeSphericalVoxelGroup', () {
    var voxelsPerUnit = 100;
    var voxelSize = 1 / voxelsPerUnit;

    // Should give one voxel.
    var oneVoxel = computeSphericalVoxelGroup(voxelSize / 2, voxelsPerUnit);
    printSlices(oneVoxel, 3);
    expect(oneVoxel.length, equals(3));
    expect(oneVoxel[0] + oneVoxel[1] + oneVoxel[2], equals(0));

    // Should give extra voxel on each face.
    var sevenVoxels = computeSphericalVoxelGroup(
        sqrt(2 * pow(voxelSize / 2, 2)), voxelsPerUnit);
    printSlices(sevenVoxels, 5);
    expect(sevenVoxels.length, equals(3 + 6 * 3));

    // Should give 3x3x3 voxels.
    var nineVoxels = computeSphericalVoxelGroup(voxelSize * 1.5, voxelsPerUnit);
    printSlices(nineVoxels, 5);
    expect(nineVoxels.length, equals(3 * 3 * 3 * 3));
  });
}

void printSlices(List<int> voxels, int size) {
  for (var i = 0; i < size; i++) {
    printSlice(voxels, i - ((size - 1) / 2).floor(), size);
    print('');
  }
}

void printSlice(List<int> voxels, int z, int size) {
  int sub = ((size - 1) / 2).floor();
  for (var x = 0; x < size; x++) {
    // Create a single line.
    var line = '';

    for (var y = 0; y < size; y++) {
      // Check if this field is in the voxel group.
      var yes = false;
      for (var i = 0; i < voxels.length; i += 3) {
        if (voxels[i] == z &&
            voxels[i + 1] == x - sub &&
            voxels[i + 2] == y - sub) {
          line += '#';
          yes = true;
          break;
        }
      }
      if (!yes) {
        line += '.';
      }
    }

    print(line);
  }
}

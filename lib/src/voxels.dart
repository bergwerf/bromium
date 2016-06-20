// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

class VoxelSpace {
  /// Number of voxels per input unit.
  final int _voxelsPerUnit;

  /// Voxel space size
  static const int size = 65536;
  static const int sizeHalf = 32768;

  /// Constructor
  VoxelSpace(double granularity) : _voxelsPerUnit = (1 / granularity).ceil();

  /// Minmal perfect hash function that maps a voxel position and type into
  /// a 64 bit integer.
  ///
  /// If [voxelSpaceSize] is updated this function should be updated as well.
  /// The maximum value for [type] is `31`.
  ///
  ///     hash = (ntypes * space^2) * x +
  ///            (ntypes * space^1) * y +
  ///            (ntypes * space^0) * z +
  ///            type
  ///
  ///     uint16: 2^16
  ///     ECMA max int: 2^53 - 1
  ///     largest voxel hash: ntypes * (space^3 + space^2 * space^1 + 1)
  ///
  ///     max number of types:
  ///       floor((2^53-1) / (2^(16*3) + 2^(16*2) + 2^(16*1) + 1)) = 31
  ///
  int voxelAddress(int x, int y, int z, int type) {
    return 31 * (4294967296 * x + 65536 * y + z) + type;
  }

  /// Same as [voxelAddress] but without adding type information.
  int plainVoxelAddress(int x, int y, int z) {
    return 4294967296 * x + 65536 * y + z;
  }

  /// Convert units to voxels.
  double utov(double units) => units * _voxelsPerUnit;

  /// Convert point coordinate to voxel coordinate
  Vector3 point(double x, double y, double z) {
    // Convert to voxels and translate to voxel space center.
    return new Vector3(x * _voxelsPerUnit + sizeHalf,
        y * _voxelsPerUnit + sizeHalf, z * _voxelsPerUnit + sizeHalf);
  }

  /// Get the voxel space depth.
  double get depth => size.toDouble();
}

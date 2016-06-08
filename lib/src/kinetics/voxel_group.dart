// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

/// Function to compute a spherical voxel group for
/// [_BindReaction.nearVoxelGroup]. Note that the (0, 0, 0) voxel must be the
/// center of the voxel group.
List<int> computeSphericalVoxelGroup(double radius, int voxelsPerUnit) {
  // Convert input to voxels (not rounded).
  var r = radius * voxelsPerUnit;

  // Output voxels
  var v = new List<int>();

  // Iterate through slices
  for (var z = 0; z < r + .5; z++) {
    // Compute slice base radius.
    var sr = z == 0 ? r : sqrt(pow(r, 2) - pow(z - .5, 2));

    // Iterate through strips
    for (var x = 0; x < sr + .5; x++) {
      // Compute strip length
      var sl = x == 0 ? sr : sqrt(pow(sr, 2) - pow(x - .5, 2));

      // Add voxel
      for (var y = 0; y < sl + .5; y++) {
        v = _computeSphericalVoxelGroupAddVoxel([x, y, z], v);
        v = _computeSphericalVoxelGroupAddVoxel([x, y, -z], v);
        v = _computeSphericalVoxelGroupAddVoxel([x, -y, z], v);
        v = _computeSphericalVoxelGroupAddVoxel([x, -y, -z], v);
        v = _computeSphericalVoxelGroupAddVoxel([-x, y, z], v);
        v = _computeSphericalVoxelGroupAddVoxel([-x, y, -z], v);
        v = _computeSphericalVoxelGroupAddVoxel([-x, -y, z], v);
        v = _computeSphericalVoxelGroupAddVoxel([-x, -y, -z], v);
      }
    }
  }

  return v;
}

/// Helper function for [computeSphericalVoxelGroup]
List<int> _computeSphericalVoxelGroupAddVoxel(
    List<int> coords, List<int> dest) {
  // Check if this vertex already exists.
  for (var i = 0; i < dest.length; i += 3) {
    if (dest[i] == coords[0] &&
        dest[i + 1] == coords[1] &&
        dest[i + 2] == coords[2]) {
      return dest;
    }
  }

  // The vertex does not exist; add it.
  return dest..addAll(coords);
}

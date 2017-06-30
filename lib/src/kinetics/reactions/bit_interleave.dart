// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.kinetics;

int _signedMask10Interleave2(int _x) {
  var x = _x;
  x &= 0x3ff;
  x ^= 0x200; // Fix sign
  x = (x | x << 16) & 0x30000ff;
  x = (x | x << 8) & 0x300f00f;
  x = (x | x << 4) & 0x30c30c3;
  x = (x | x << 2) & 0x9249249;
  return x;
}

int _signedMask21interleave2(int _x) {
  var x = _x;
  x &= 0x1fffff;
  x ^= 0x100000; // Fix sign
  x = (x | x << 32) & 0x1f00000000ffff;
  x = (x | x << 16) & 0x1f0000ff0000ff;
  x = (x | x << 8) & 0x100f00f00f00f00f;
  x = (x | x << 4) & 0x10c30c30c30c30c3;
  x = (x | x << 2) & 0x1249249249249249;
  return x;
}

int interleave3xInt32inUint32(int _x, int _y, int _z) {
  final x = _signedMask10Interleave2(_x);
  final y = _signedMask10Interleave2(_y);
  final z = _signedMask10Interleave2(_z);
  return x | (y << 1) | (z << 2);
}

int interleave3xInt32inUint64(int _x, int _y, int _z) {
  final x = _signedMask21interleave2(_x);
  final y = _signedMask21interleave2(_y);
  final z = _signedMask21interleave2(_z);
  return x | (y << 1) | (z << 2);
}

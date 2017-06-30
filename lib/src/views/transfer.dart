// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.views;

/// Transfer Float32List.
Float32List transferFloat32List(
    ByteBuffer buffer, int offset, bool copy, Float32List src) {
  final dst = new Float32List.view(buffer, offset, src.length);
  if (copy) {
    dst.setAll(0, src);
  }
  return dst;
}

/// Transfer Uint32List.
Uint32List transferUint32List(
    ByteBuffer buffer, int offset, bool copy, Uint32List src) {
  final dst = new Uint32List.view(buffer, offset, src.length);
  if (copy) {
    dst.setAll(0, src);
  }
  return dst;
}

/// Transfer Vector3
Vector3 transferVector3(ByteBuffer buffer, int offset, Vector3 src,
    {bool copy}) {
  final dst = new Vector3.fromBuffer(buffer, offset);
  if (copy) {
    dst.copyFromArray(src.storage);
  }
  return dst;
}

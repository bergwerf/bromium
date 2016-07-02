// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.views;

/// Base class for all data structures that contain dynamic data that can be
/// written to a byte buffer segment and transferred to a new byte buffer.
abstract class Transferrable {
  /// The number of bytes that is used by one instance
  int get sizeInBytes;

  /// Transfers the data to the [buffer] at [offset], copy the old data into the
  /// new buffer if [copy] is true. Returns the new offset.
  int transfer(ByteBuffer buffer, int offset, [bool copy = true]);
}

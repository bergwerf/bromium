// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

library bromium.logging;

import 'package:logging/logging.dart';

final _groupLogger = new Logger('GroupLogger');

/// Start log group.
void group(Logger logger, String name) {
  logger.info('group: $name');
}

/// End log group.
void groupEnd() {
  _groupLogger.info('groupEnd');
}

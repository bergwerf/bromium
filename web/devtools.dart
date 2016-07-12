// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

@JS('console')
library devtools;

import 'package:js/js.dart';

external void log(String message, [String style]);
external void error(Object error);
external void trace(Object stackTrace);
external void group([String label]);
external void groupCollapsed([String label]);
external void groupEnd();

void print(String message, {String color: null}) {
  if (color != null) {
    log('%c$message', "color: $color;");
  } else {
    log(message);
  }
}

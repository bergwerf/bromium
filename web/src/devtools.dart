// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

@JS('console')
library devtools;

import 'package:js/js.dart';
import 'package:logging/logging.dart';

external void log(String message, [String style]);
external void error(Object error);
external void trace(Object stackTrace);
external void group([String label]);
external void groupCollapsed([String label]);
external void groupEnd();

void println(String message, {String color: null}) {
  if (color != null) {
    log('%c$message', "color: $color;");
  } else {
    log(message);
  }
}

/// A possible setup to connect logging to the devtools.
void setupLogging() {
  var logColor = {
    Level.FINEST.value: 'black',
    Level.FINER.value: 'black',
    Level.FINE.value: 'black',
    Level.CONFIG.value: 'gray',
    Level.INFO.value: 'green',
    Level.WARNING.value: 'orange',
    Level.SEVERE.value: 'orangered',
    Level.SHOUT.value: 'red'
  };
  var groupStack = [];

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    if (rec.message.startsWith('group: ')) {
      group('${rec.loggerName}.${rec.message.substring(7)}');
      groupStack.add(rec.loggerName);
    } else if (rec.message == 'groupEnd') {
      groupEnd();
      groupStack.removeLast();
    } else {
      if (groupStack.isNotEmpty && rec.loggerName == groupStack.last) {
        println('${rec.message}', color: logColor[rec.level.value]);
      } else {
        println('[${rec.loggerName}] ${rec.message}',
            color: logColor[rec.level.value]);
      }

      if (rec.error != null) {
        error(rec.error);
      }
    }
  });
}

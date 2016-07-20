// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

import 'dart:html';

void setupUi() {
  document.querySelectorAll('.tab-header').onClick.listen((MouseEvent e) {
    final target = e.target as HtmlElement;

    // Switch tab.
    document.querySelectorAll('.tab-header').classes.add('inactive');
    target.classes.remove('inactive');

    // Switch panel.
    document.querySelectorAll('.tab-panel').classes.add('hidden');
    document
        .querySelectorAll('#${target.innerHtml.toLowerCase()}-tab')
        .classes
        .remove('hidden');
  });
}

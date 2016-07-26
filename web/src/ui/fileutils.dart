// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

/// FileSaver.js saveAs like function
void saveAs(Blob blob, String name) {
  final url = Url.createObjectUrlFromBlob(blob);
  new AnchorElement()
    ..href = url
    ..download = name
    ..click();
  Url.revokeObjectUrl(url);
}

/// Open a file with the given content type.
Future<String> openFile(String contentType) {
  final completer = new Completer<String>();
  final input = new InputElement(type: 'file')..accept = contentType;
  input.onChange.listen((_) {
    final reader = new FileReader();
    reader.onLoadEnd.listen((_) {
      completer.complete(reader.result);
    });
    reader.readAsText(input.files.first);
  });
  input.click();
  return completer.future;
}

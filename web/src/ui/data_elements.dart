// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

/// Base class for all custom html elements
abstract class CustomElement {
  Element get node;
}

/// Base class for all custom data input elements
abstract class DataElement extends CustomElement {
  dynamic get data;

  DataElement clone();
}

/// Data element for an html select widget
class ChoiceDataElement extends DataElement {
  SelectElement node;

  final List<String> options;

  ChoiceDataElement(this.options) {
    node = new SelectElement();
    for (final option in options) {
      node.append(new OptionElement(value: option)..text = option);
    }
  }

  ChoiceDataElement clone() => new ChoiceDataElement(options);

  String get data => node.value;
}

/// Data element for an html input element
class InputDataElement extends DataElement {
  InputElement node;

  InputDataElement({String type: 'text'}) {
    node = new InputElement(type: type);
  }

  InputDataElement clone() => new InputDataElement(type: node.type);

  dynamic get data => node.value;
}

/// Data element for numeric data input
class NumericDataElement extends InputDataElement {
  final num step, min, max;

  NumericDataElement({this.step: 1, this.min: null, this.max: null})
      : super(type: 'number') {
    node.step = step.toString();
    if (min != null) {
      node.min = min.toString();
    }
    if (max != null) {
      node.max = max.toString();
    }
  }

  NumericDataElement clone() =>
      new NumericDataElement(step: step, min: min, max: max);

  double get data => double.parse(node.value);
}

/// Data element for hex color input
class ColorDataElement extends InputDataElement {
  ColorDataElement() : super(type: 'text') {
    node.spellcheck = false;

    // Update the background to the entered color.
    node.onChange.listen((_) {
      node.style.background = node.value;
      final grayscale = new Vector4.zero();
      Colors.toGrayscale(data, grayscale);
      node.style.color = grayscale.x < .5 ? '#eee' : '#111';
    });
  }

  ColorDataElement clone() => new ColorDataElement();

  Vector4 get data {
    var result = new Vector4.zero();
    Colors.fromHexString(node.value, result);
    return result;
  }
}

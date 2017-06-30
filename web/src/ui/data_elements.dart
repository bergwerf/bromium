// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

/// Base class for all custom html elements
abstract class CustomElement {
  /// Element HTML node
  Element get node;
}

/// Base class for all custom data input elements
abstract class DataElement<T> extends CustomElement {
  /// Entered value
  T get value;

  /// Set the node value
  set value(T value);

  /// Create new HTML node that is equal to this one
  DataElement clone();
}

/// Data element for an html select widget
class ChoiceDataElement extends DataElement<String> {
  @override
  SelectElement node;

  /// All choice options
  final List<String> options;

  ChoiceDataElement(this.options) {
    node = new SelectElement();
    for (final option in options) {
      final optionElement = new OptionElement(value: option);
      optionElement.text = option;
      if (option == value) {
        optionElement.selected = true;
      }
      node.append(optionElement);
    }
  }

  @override
  ChoiceDataElement clone() => new ChoiceDataElement(options);

  @override
  String get value => node.value;

  @override
  set value(String value) => node.selectedIndex = options.indexOf(value);
}

/// Data element for an html input element
class TextInputElement extends DataElement<String> {
  @override
  InputElement node;

  TextInputElement({String type: 'text'}) {
    node = new InputElement(type: type);
  }

  @override
  TextInputElement clone() => new TextInputElement(type: node.type);

  @override
  String get value => node.value;

  @override
  set value(String value) => node.value = value;
}

/// Data element for numeric data input
abstract class _NumericDataElement<T> extends DataElement<T> {
  @override
  InputElement node;

  /// Numeric input step size, and min/max value
  final num step, min, max;

  _NumericDataElement(
      {this.step: 1, this.min: null, this.max: null, num value: 0}) {
    node = new InputElement(type: 'number');
    node.step = step.toString();
    if (min != null) {
      node.min = min.toString();
    }
    if (max != null) {
      node.max = max.toString();
    }
  }
}

/// Data element for integer input
class IntDataElement extends _NumericDataElement<int> {
  IntDataElement({int step: 1, int min: null, int max: null, num value: 0})
      : super(step: step, min: min, max: max);

  @override
  IntDataElement clone() =>
      new IntDataElement(step: step, min: this.min, max: this.max);

  @override
  int get value => int.parse(node.value);

  @override
  set value(int value) => node.value = value.toString();
}

/// Data element for floating point input
class FloatDataElement extends _NumericDataElement<double> {
  FloatDataElement(
      {double step: 1.0, double min: null, double max: null, num value: 0})
      : super(step: step, min: min, max: max);

  @override
  FloatDataElement clone() =>
      new FloatDataElement(step: step, min: this.min, max: this.max);

  @override
  double get value => double.parse(node.value);

  @override
  set value(double value) => node.value = value.toString();
}

/// Data element for Vector3 input
class Vector3DataElement extends DataElement<Vector3> {
  @override
  InputElement node;

  Vector3DataElement() {
    node = new InputElement(type: 'text');
  }

  @override
  Vector3DataElement clone() => new Vector3DataElement();

  @override
  Vector3 get value {
    final vector = new Vector3.zero();
    final values = node.value.split(',');

    // In the special case there is only one value, use the value for all three
    // vector dimensions.
    if (values.length == 1) {
      return new Vector3.all(double.parse(values.first));
    } else {
      for (var i = 0, j = 0; i < 3 && i < values.length; i++) {
        if (values[i].isNotEmpty) {
          try {
            final value = double.parse(values[i]);

            vector.storage[j] = value;
            j++;
          } on Exception {
            continue;
          }
        }
      }
      return vector;
    }
  }

  @override
  set value(Vector3 value) => node.value =
      '${float32To64(value.x)}, ${float32To64(value.y)}, ${float32To64(value.z)}';
}

/// Data element for hex color input
class ColorDataElement extends DataElement<Vector4> {
  @override
  InputElement node;

  ColorDataElement() {
    node = new InputElement(type: 'text');
    node.spellcheck = false;

    // Update the background to the entered color.
    node.onChange.listen((_) => updateColors());
  }

  @override
  ColorDataElement clone() => new ColorDataElement();

  /// Update the input background and foreground using the entered color.
  void updateColors() {
    node.style.background = node.value;
    final grayscale = new Vector4.zero();
    Colors.toGrayscale(value, grayscale);
    node.style.color = grayscale.x < .5 ? '#eee' : '#111';
  }

  @override
  Vector4 get value {
    final result = new Vector4.zero();
    try {
      Colors.fromHexString(node.value, result);
    } on Exception {
      return new Vector4(0.0, 0.0, 0.0, 1.0);
    }
    return result;
  }

  @override
  set value(Vector4 value) {
    final hexString = Colors.toHexString(value).padLeft(6, '0');
    node.value = '#$hexString';
    updateColors();
  }
}

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
abstract class DataElement extends CustomElement {
  /// Entered value
  dynamic get value;

  /// Set the node value
  set value(dynamic value);

  /// Create new HTML node that is equal to this one
  DataElement clone();
}

/// Data element for an html select widget
class ChoiceDataElement extends DataElement {
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

  ChoiceDataElement clone() => new ChoiceDataElement(options);

  String get value => node.value;
  set value(String value) => node.selectedIndex = options.indexOf(value);
}

/// Data element for an html input element
class InputDataElement extends DataElement {
  InputElement node;

  InputDataElement({String type: 'text'}) {
    node = new InputElement(type: type);
  }

  InputDataElement clone() => new InputDataElement(type: node.type);

  dynamic get value {
    print(node.value);
    return node.value;
  }

  set value(dynamic value) => node.value = value;
}

/// Data element for numeric data input
class _NumericDataElement extends InputDataElement {
  /// Numeric input step size, and min/max value
  final num step, min, max;

  _NumericDataElement(
      {this.step: 1, this.min: null, this.max: null, num value: 0})
      : super(type: 'number') {
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
class IntDataElement extends _NumericDataElement {
  IntDataElement({int step: 1, int min: null, int max: null, num value: 0})
      : super(step: step, min: min, max: max);

  IntDataElement clone() =>
      new IntDataElement(step: step, min: this.min, max: this.max);

  int get value => int.parse(node.value);
  set value(int value) => node.value = value.toString();
}

/// Data element for floating point input
class FloatDataElement extends _NumericDataElement {
  FloatDataElement(
      {double step: 1.0, double min: null, double max: null, num value: 0})
      : super(step: step, min: min, max: max);

  FloatDataElement clone() =>
      new FloatDataElement(step: step, min: this.min, max: this.max);

  double get value => double.parse(node.value);
  set value(double value) => node.value = value.toString();
}

/// Data element for Vector3 input
class Vector3DataElement extends InputDataElement {
  Vector3DataElement() : super(type: 'text');

  Vector3DataElement clone() => new Vector3DataElement();

  Vector3 get value {
    final vector = new Vector3.zero();
    final values = node.value.split(',');
    for (var i = 0, j = 0; i < 3 && i < values.length; i++) {
      if (values[i].isNotEmpty) {
        try {
          var value = double.parse(values[i]);

          vector.storage[j] = value;
          j++;
        } catch (e) {
          continue;
        }
      }
    }
    return vector;
  }

  set value(Vector3 value) => node.value =
      '${float32To64(value.x)}, ${float32To64(value.y)}, ${float32To64(value.z)}';
}

/// Data element for hex color input
class ColorDataElement extends InputDataElement {
  ColorDataElement() : super(type: 'text') {
    node.spellcheck = false;

    // Update the background to the entered color.
    node.onChange.listen((_) => updateColors());
  }

  ColorDataElement clone() => new ColorDataElement();

  /// Update the input background and foreground using the entered color.
  void updateColors() {
    node.style.background = node.value;
    final grayscale = new Vector4.zero();
    Colors.toGrayscale(value, grayscale);
    node.style.color = grayscale.x < .5 ? '#eee' : '#111';
  }

  Vector4 get value {
    var result = new Vector4.zero();
    try {
      Colors.fromHexString(node.value, result);
    } catch (e) {
      return new Vector4(0.0, 0.0, 0.0, 1.0);
    }
    return result;
  }

  set value(Vector4 value) {
    var hexString = Colors.toHexString(value).padLeft(6, '0');
    node.value = '#$hexString';
    updateColors();
  }
}

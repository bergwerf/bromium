// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium.ui;

const _jsonClassKey = '__dartClass';

/// Dirty hack to get around issue sdk#26951
double float32To64(double value) {
  final digits = value.floor().toString().length;
  final factor = pow(10, 8 - digits);
  value = value * factor;
  value = value.roundToDouble();
  value = value / factor;
  return value;
}

List<double> _from32To64FloatList(Float32List src) =>
    new List<double>.generate(src.length, (int i) => float32To64(src[i]));

dynamic toJsonExtra(dynamic object) {
  if (object is Map) {
    return new Map.fromIterable(object.keys,
        value: (dynamic key) => toJsonExtra(object[key]));
  } else if (object is List) {
    return new List.generate(object.length, (int i) => toJsonExtra(object[i]));
  } else {
    return _dartClassToJson(object);
  }
}

dynamic _dartClassToJson(dynamic object) {
  if (object is Tuple2) {
    return {
      _jsonClassKey: 'Tuple2',
      'item1': object.item1,
      'item2': object.item2
    };
  } else if (object is Vector2) {
    return {
      _jsonClassKey: 'Vector2',
      'storage': _from32To64FloatList(object.storage)
    };
  } else if (object is Vector3) {
    return {
      _jsonClassKey: 'Vector3',
      'storage': _from32To64FloatList(object.storage)
    };
  } else if (object is Vector4) {
    return {
      _jsonClassKey: 'Vector4',
      'storage': _from32To64FloatList(object.storage)
    };
  } else {
    return object;
  }
}

dynamic _jsonToDartClass(dynamic object) {
  switch (object[_jsonClassKey]) {
    case 'Tuple2':
      return new Tuple2(
          fromJsonExtra(object['item1']), fromJsonExtra(object['item2']));

    case 'Vector2':
      return new Vector2.array(new List<double>.generate(
          object['storage'].length,
          (int i) => object['storage'][i].toDouble()));

    case 'Vector3':
      return new Vector3.array(new List<double>.generate(
          object['storage'].length,
          (int i) => object['storage'][i].toDouble()));

    case 'Vector4':
      return new Vector4.array(new List<double>.generate(
          object['storage'].length,
          (int i) => object['storage'][i].toDouble()));

    default:
      return null;
  }
}

dynamic fromJsonExtra(dynamic object) {
  if (object is Map) {
    if (object.containsKey(_jsonClassKey)) {
      return _jsonToDartClass(object);
    }
    return new Map.fromIterable(object.keys,
        value: (dynamic key) => fromJsonExtra(object[key]));
  } else if (object is List) {
    return new List.generate(
        object.length, (int i) => fromJsonExtra(object[i]));
  } else {
    return object;
  }
}

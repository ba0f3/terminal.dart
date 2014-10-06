import 'terminal.dart';

class Stack {
  var _data = new List<Interpreter>();
  int pos = 0;

  Stack({List init: null}) {
    if (init != null) _data = init;
  }

  dynamic map(Function f) {
    return _data.map(f);
  }

  int size() {
    return _data.length;
  }

  Interpreter pop() {
    if (_data.length == 0) {
      return null;
    } else {
      Interpreter value = _data[_data.length - 1];
      _data = _data.slice(0, _data.length - 1);
      return value;
    }
  }

  Interpreter push(Interpreter i) {
    _data.add(i);
    return i;
  }

  Interpreter top() {
    return _data.length > 0 ? _data[_data.length - 1] : null;
  }
}

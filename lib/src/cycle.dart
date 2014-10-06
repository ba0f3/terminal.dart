part of terminal;

class Cycle {
  var _data = new List<Terminal>();
  int pos = 0;

  Cycle({List init: null}) {
    if(init != null) _data = init;
  }

  List<Terminal> get() {
    return _data;
  }

  Terminal rotate() {
    if(_data.length == 1) return _data[0];
    else {
      if(pos == _data.length - 1) pos = 0;
      else ++pos;
    }
    return _data[pos];
  }

  int length() {
    return _data.length;
  }

  void set(Terminal item) {
    if(_data.contains(item)) pos = _data.indexOf(item);
    else append(item);
  }

  Terminal front() {
    return _data[pos];
  }

  void append(Terminal item) {
    _data.add(item);
  }
}

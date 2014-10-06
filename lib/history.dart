import 'dart:html';
import 'dart:convert';

class History {
  bool _enabled = true;
  String storage_key = 'commands';
  int _size = 0;
  List<String> _data;
  int pos;

  History({String name: '', int size: 0}) {
    if(name != '') storage_key= name + '_commands';
    if(size > 0) _size = size;

    _data = JSON.decode(window.localStorage[storage_key]);
    reset();
  }

  void append(String command) {
    if(_enabled) {
      if(_data.last != command) {
        _data.add(command);
        if(_size > 0 && _data.length > _size) {
          _data.removeAt(0);
        }
        reset();

        window.localStorage[storage_key] = JSON.encode(_data);
      }
    }
  }

  List<String> data() {
    return _data;
  }

  void reset() {
    pos = _data.length-1;
  }

  String last() {
    return _data.last;
  }

  bool end() {
    return pos == _data.length-1;
  }

  int position() {
    return pos;
  }

  String current() {
    return _data.elementAt(pos);
  }

  String next() {
    if(pos < _data.length-1) ++pos;
    if(pos != -1) return _data[pos];
    return null;
  }

  String previous() {
    int old = pos;
    if(pos > 0) --pos;
    if(old != -1) return _data[pos];
    return null;
  }

  void clear() {
    _data.clear();
    purge();
  }

  bool enabled() {
    return _enabled;
  }

  void enable() {
    _enabled = true;
  }

  void disable() {
    _enabled = false;
  }

  void purge() {
    window.localStorage.remove(storage_key);
  }
}

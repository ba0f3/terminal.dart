part of terminal;

class CommandLine {
  var _root = new DivElement();
  var clip = new TextAreaElement();

  int num_chars; // calculated by draw_prompt
  int prompt_len;
  bool reverse_search = false;
  String reverse_search_string = '';
  int reverse_search_position = null;
  String backup_prompt;
  bool _mask = false;
  String command = '';
  String selected_text = ''; // text from selection using CTRL+SHIFT+C (as in Xterm)
  String kill_text = ''; // text from command that kill part of the command
  int _position = 0;
  dynamic _prompt;
  bool enabled = true;
  int historySize = 60;
  String _name;
  HistoryManager history;
  SpanElement _cursor;

  Map<String, dynamic> _options;

  CommandLine(Map<String, dynamic> options) {
    _root.classes.add('cmd');
    _root.appendHtml('<span class="prompt"></span><span></span><span class="cursor">&nbsp;</span><span></span>');
    _cursor = _root.querySelector('.cursor');
    clip.classes.add('clipboard');
    _root.append(clip);

    _options = options;

    if(options.containsKey('width')) _root.clientWidth = options['width'];
    if(options.containsKey('historySize')) historySize = options['historySize'];
    if(options.containsKey('mask')) _mask = options['mask'];
    if(options.containsKey('enabled')) enabled = options['enabled'];

    name(options.containsKey('name') ? options['name'] : options.containsKey('prompt') ? options['prompt'] : '');
    _prompt = options.containsKey('prompt') ? options['prompt'] : '> ';
    draw_prompt();
    if(options.containsKey('enabled') && options['enabled'] == true) {
      enable();
    }
    window.onKeyPress.listen((KeyboardEvent event){
      bool result = false;
      if(event.ctrlKey && event.which == 99) { // Ctrl + C
        result = true;
      }

      if (!reverse_search && options['keypress'] is Function) {
        result = options['keypress'](event);
      }

      if (result) {
        if (enabled) {
          if ($.inArray(e.which, [38, 13, 0, 8]) > -1 && e.keyCode != 123 && // for F12 which === 0
          !(e.which == 38 && e.shiftKey)) {
            return false;
          } else if (!e.ctrlKey && !(e.altKey && e.which == 100) || e.altKey) { // ALT+D
            // TODO: this should be in one statement
            if (reverse_search) {
              reverse_search_string += String.fromCharCode(e.which);
              reverse_history_search();
              draw_reverse_prompt();
            } else {
              insert(String.fromCharCode(e.which));
            }
            return false;
          }
        }
      } else {
        return result;
      }
    });
    window.onKeyDown.listen(keydown_event);
  }

  void animation(bool toggle) {
    //TODO check if browser support animation
    if (toggle) {
      _cursor.classes.add('blink');
    } else {
      _cursor.classes.remove('blink');
    }
  }

  /**
   * Blinking cursor function
   */
  void blink() {
    _cursor.classes.toggle('inverted');
  }

  /**
   * Set prompt for reverse search
   */
  void draw_reverse_prompt() {
    _prompt = "(reverse-i-search)`" + reverse_search_string + "': ";
    draw_prompt();
  }

  /**
   * Disable reverse search
   */
  void clear_reverse_state() {
    _prompt = backup_prompt;
    reverse_search = false;
    reverse_search_position = null;
    reverse_search_string = '';
  }

  void reverse_history_search(bool next) {
    List<String> history_data = history.data();
    int len = history_data.length;
    String save_string;
    RegExp regex;

    if (next && reverse_search_position > 0) {
      len -= reverse_search_position;
    }

    if (reverse_search_string.length > 0) {
      for (var j=reverse_search_string.length; j>0; j--) {
        save_string = reverse_search_string..substring(0, j)..replaceAllMapped(new RegExp("([.*+{}\[\]?])"), (match){
          return '"${match.group(1)}"';
        });
        regex = new RegExp(save_string);

        for (var i=len; i--;) {
          if (regex.hasMatch(history_data[i])) {
            reverse_search_position = history_data.length - i;
            _position = 0;
            set(history_data[i], true);
            redraw();
            if (reverse_search_string.length != j) {
              reverse_search_string = reverse_search_string.substring(0, j);
              draw_reverse_prompt();
            }
            return;
          }
        }
      }
    }
    reverse_search_string = ''; // clear if not found any
  }

  /**
   * Recalculate number of characters in command line
   */
  void change_num_chars() {
    num_chars = (_root.offsetWidth/_cursor.offsetWidth).floor();
  }

  String str_repeat(str, n) {
    String result = '';
    for (var i = n; i--;) {
      result += str;
    }
    return result;
  }

  List<String> get_splited_command_line(String str) {
    var result = new List<String>();
    var first = str.substring(0, num_chars - prompt_len);
    var rest = str.substring(num_chars - prompt_len);

    result.add(first);
    result.addAll(str_parts(rest, num_chars));

    return result;
  }


  void redraw() {
    var before = _cursor.previousElementSibling;
    var after = _cursor.nextElementSibling;

    void draw_cursor_line(String str, int position) {
      int len = str.length;
      if(position == len) {
        before.setInnerHtml(Terminal.encode(str));
        _cursor.setInnerHtml('&nbsp;');
        after.setInnerHtml('');
      } else if(position == 0) {
        before.setInnerHtml('');
        _cursor.setInnerHtml(Terminal.encode(str.substring(0, 1)));
        after.setInnerHtml(Terminal.encode(str.substring(1)));
      } else {
        before.setInnerHtml(Terminal.encode(str.substring(0, position)));
        String c = str.substring(position, position + 1);
        _cursor.setInnerHtml(c == ' ' ? '&nbsp;' : Terminal.encode(c));
        if (position == str.length - 1) {
          after.setInnerHtml('');
        } else {
          after.setInnerHtml(Terminal.encode(str.substring(position + 1)));
        }
      }
    };

    void lines_after(List<String> lines) {
      Element last_ins = after;
      lines.forEach((line){
        last_ins.append(div(line)..classes.add('clear'));
      });
    };

    void lines_before(List<String> lines) {
      lines.forEach((line){
        before.insertBefore(div(line), before);
      });
    };

    int count = 0;
    //
    // main logic starts here
    //
    String str = _mask ? command.replaceAll('.*', '*') : command;
    _root.querySelector('div').remove();
    before.setInnerHtml('');

    if (str.length > num_chars - prompt_len - 1 || str.contains("\n")) {
      var arr = new List<String>();
      int i, first_len;
      int tabs = count_substring(str, "\t");
      int tabs_rm = tabs * 3;

      if (tabs > 0) {
        str = str.replaceAll('\t', '\x00\x00\x00\x00');
      }

      // command contains new line characters
      if(count_substring(str, "\n") > 0) {
        List<String> tmp = str.split("\n");
        first_len = num_chars - prompt_len - 1;
        // empty character after each line
        for (i=0; i<tmp.length-1; ++i) {
          tmp[i] += ' ';
        }
        // split first line
        if (tmp[0].length > first_len) {
          arr.add(tmp[0].substring(0, first_len));
          arr.addAll(str_parts(tmp[0].substring(first_len), num_chars));
        } else {
          arr.add(tmp[0]);
        }

        // process rest of the lines
        for (i=1; i<tmp.length; ++i) {
          if (tmp[i].length > num_chars) {
            arr = arr.addAll(str_parts(tmp[i], num_chars));
          } else {
            arr.add(tmp[i]);
          }
        }
      } else {
        arr = get_splited_command_line(str);
      }

      if (tabs > 0) {
        arr = arr.map((line){
          return line.replaceAll('\x00\x00\x00\x00', '\t');
        });
      }
      first_len = arr[0].length;

      //cursor in first line
      if (first_len == 0 && arr.length == 1) {
        // skip empty line
      } else if (_position < first_len) {
        draw_cursor_line(arr[0], _position);
        lines_after(arr.slice(1));
      } else if (_position == first_len) {
        before.before(div(arr[0]));
        draw_cursor_line(arr[1], 0);
        lines_after(arr.slice(2));
      } else {
        int num_lines = arr.length;
        int offset = 0;
        if (_position < first_len) {
          draw_cursor_line(arr[0], _position);
          lines_after(arr.remove(1));
        } else if (_position == first_len) {
          before.insertBefore(div(arr[0]), before);
          draw_cursor_line(arr[1], 0);
          lines_after(arr.remove(2));
        } else {
          var last = arr.slice(-1)[0];
          var from_last = str.length - _position;
          var last_len = last.length;
          var pos = 0;
          if (from_last <= last_len) {
            lines_before(arr.slice(0, -1));
            pos = last_len == from_last ? 0 : last_len-from_last;
            draw_cursor_line(last, pos+tabs_rm);
          } else {
            // in the middle
            if (num_lines == 3) {
              before.insertBefore(div(Terminal.encode(arr[0])), before);
              draw_cursor_line(arr[1], _position-first_len-1);
              after.parent.append(div(Terminal.encode(arr[2])));
            } else {
              // more lines, cursor in the middle
              int line_index;
              String current;
              pos = _position;
              for (i=0; i<arr.length; ++i) {
                var current_len = arr[i].length;
                if (pos > current_len) {
                  pos -= current_len;
                } else {
                  break;
                }
              }
              current = arr[i];
              line_index = i;
              // cursor on first character in line
              if (pos == current.length) {
                pos = 0;
                current = arr[++line_index];
              }
              draw_cursor_line(current, pos);
              lines_before(arr.getRange(0, line_index));
              lines_after(arr.sublist(line_index+1));
            }
          }
        }
      }
    } else {
      if (str == '') {
        before.setInnerHtml('');
        _cursor.setInnerHtml('&nbsp;');
        after.setInnerHtml('');
      } else {
        draw_cursor_line(str, _position);
      }
    }
  }
  String last_command;
  /**
   * Draw prompt that can be a function or a string
   */
  void draw_prompt() {
    SpanElement prompt_node = _root.querySelector('.prompt');
    void set(prompt) {
      prompt_len = skipFormattingCount(prompt);
      prompt_node.setInnerHtml(Terminal.format(Terminal.encode(prompt)));
    }
    if(_prompt is String) {
      set(_prompt);
    } else if(_prompt is Function) {
      prompt(set);
    }
  }

  void parse() {
    clip.focus();
    new Timer(1, (){
      insert(clip.val());
      clip.blur().val('');
    });
  }

  bool first_up_history = true;
  bool keydown_event(KeyboardEvent e) {
    bool result;
    int pos, len;
    if (_options['keydown'] is Function) {
      result = _options['keydown'](e);
      if (result != undefined) {
        return result;
      }
    }
    if(enabled) {
      if(e.which != 38 &&  !(e.which == 80 && e.ctrlKey)) {
        first_up_history = true;
      }
      // arrows / Home / End / ENTER
      if (reverse_search && (e.which == 35 || e.which == 36 ||
          e.which == 37 || e.which == 38 ||
          e.which == 39 || e.which == 40 ||
          e.which == 13 || e.which == 27)) {
        clear_reverse_state();
        draw_prompt();
        if (e.which == 27) { // ESC
          command = '';
        }
        redraw();
        // finish reverse search and execute normal event handler
        keydown_event.call(this, e);
      } else if (e.altKey) {
        // Chrome on Windows sets ctrlKey and altKey for alt
        // need to check for alt first
        //if (e.which === 18) { // press ALT
        if (e.which == 68) { //ALT+D
          set(command.substring(0, _position) + command.substring(_position).replaceAllMapped(new RegExp("[^ ]+ |[^ ]+\$"), ''), true);
          // chrome jump to address bar
          return false;
        }
        return true;
      } else if (e.keyCode == 13) { //enter
        if (e.shiftKey) {
          self.insert('\n');
        } else {
          if (history && command && !_mask &&
            ((_options['historyFilter'] is Function &&
            _options['historyFilter'](command)) || !_options['historyFilter'])) {
              history.append(command);
          }
          String tmp = command;
          history.reset();
          set('');
          if (_options['commands']) {
            _options['commands'](tmp);
          }
          if (_prompt is Function) {
            draw_prompt();
          }
        }
      } else if (e.which == 8) { //backspace
        if (reverse_search) {
          reverse_search_string = reverse_search_string.substring(0, -1);
          draw_reverse_prompt();
        } else {
          if (command != '' && _position > 0) {
            command = command.substring(0, _position - 1) +
            command.substring(_position, command.length);
            --_position;
            redraw();
          }
        }
      } else if (e.which == 67 && e.ctrlKey && e.shiftKey) { // CTRL+SHIFT+C
        selected_text = getSelectedText();
      } else if (e.which == 86 && e.ctrlKey && e.shiftKey) {
        if (selected_text != '') {
          insert(selected_text);
        }
      } else if (e.which == 9 && !(e.ctrlKey || e.altKey)) { // TAB
        insert('\t');
      } else if (e.which == 46) {
        //DELETE
        if (command != '' && _position < command.length) {
          command = command.substring(0, _position) +
          command.substring(_position + 1, command.length);
          redraw();
        }
        return true;
      } else if (history && e.which == 38 || (e.which == 80 && e.ctrlKey)) {
        //UP ARROW or CTRL+P
        if (first_up_history) {
          last_command = command;
          set(history.current());
        } else {
          set(history.previous());
        }
        first_up_history = false;
      } else if (history && e.which == 40 || (e.which == 78 && e.ctrlKey)) {
        //DOWN ARROW or CTRL+N
        set(history.end() ? last_command : history.next());
      } else if (e.which == 37 || (e.which == 66 && e.ctrlKey)) {
        //CTRL+LEFT ARROW or CTRL+B
        if (e.ctrlKey && e.which != 66) {
          len = _position - 1;
          pos = 0;
          if (command[len] == ' ') {
            --len;
          }
          for (var i = len; i > 0; --i) {
            if (command[i] == ' ' && command[i+1] != ' ') {
              pos = i + 1;
              break;
            } else if (command[i] == '\n' && command[i+1] != '\n') {
              pos = i;
              break;
            }
          }
          position(pos);
        } else {
          //LEFT ARROW or CTRL+B
          if (_position > 0) {
            --_position;
            redraw();
          }
        }
      } else if (e.which == 82 && e.ctrlKey) { // CTRL+R
        if (reverse_search) {
          reverse_history_search(true);
        } else {
          backup_prompt = _prompt;
          draw_reverse_prompt();
          last_command = command;
          command = '';
          redraw();
          reverse_search = true;
        }
      } else if (e.which == 71 && e.ctrlKey) { // CTRL+G
        if (reverse_search) {
          _prompt = backup_prompt;
          draw_prompt();
          command = last_command;
          redraw();
          reverse_search = false;
          reverse_search_string = '';
        }
      } else if (e.which == 39 || (e.which == 70 && e.ctrlKey)) {
        //RIGHT ARROW OR CTRL+F
        if (e.ctrlKey && e.which != 70) {
          // jump to beginning or end of the word
          if (command[_position] == ' ') {
            ++_position;
          }
          //FIXME regex
          /*
          RegExp re = /\S[\n\s]{2,}|[\n\s]+\S?/;
          var match = command.slice(position).match(re);
          if (!match || match[0].match(/^\s+$/)) {
            position = command.length;
          } else {
            if (match[0][0] !== ' ') {
              position += match.index + 1;
            } else {
              position += match.index + match[0].length - 1;
              if (match[0][match[0].length-1] !== ' ') {
                --position;
              }
            }
          }*/
          redraw();
        } else {
          if (_position < command.length) {
            ++_position;
            redraw();
          }
        }
      } else if (e.which == 123) { //F12 - Allow Firebug
        return true;
      } else if (e.which == 36) { //HOME
        position(0);
      } else if (e.which == 35) { //END
        position(command.length);
      } else if (e.shiftKey && e.which == 45) { // Shift+Insert
        paste();
        return true;
      } else if (e.ctrlKey || e.metaKey) {
        if (e.which == 192) { // CMD+` switch browser window on Mac
          return true;
        }
        if (e.metaKey) {
          if(e.which == 82) { // CMD+r page reload in Chrome Mac
            return true;
          } else if(e.which == 76) {
            return true; // CMD+l jump into Omnibox on Chrome Mac
          }
        }
        if (e.shiftKey) { // CTRL+SHIFT+??
          if (e.which == 84) {
            //CTRL+SHIFT+T open closed tab
            return true;
          }
          //} else if (e.altKey) { //ALT+CTRL+??
        } else {
          if (e.which == 81) { // CTRL+W
            // don't work in Chromium (can't prevent close tab)
            if (command != '' && position != 0) {
              var first = command.slice(0, position);
              var last = command.slice(position+1);
              //FIXME
              /*
              var m = first.match(/([^ ]+ *$)/);
              position = first.length-m[0].length;
              kill_text = first.slice(position);
              command = first.slice(0, position) + last;
              */
              redraw();
            }
            return false;
          } else if (e.which == 72) { // CTRL+H
            if (command != '' && position > 0) {
              command = command.slice(0, --position);
              if (position < command.length-1) {
                command += command.slice(position);
              }
              redraw();
            }
            return false;
            //NOTE: in opera charCode is undefined
          } else if (e.which == 65) { //CTRL+A
            self.position(0);
          } else if (e.which == 69) { //CTRL+E
            self.position(command.length);
          } else if (e.which == 88 || e.which == 67 || e.which == 84) { //CTRL+X CTRL+C CTRL+W CTRL+T
            return true;
          } else if (e.which == 89) { // CTRL+Y
            if (kill_text != '') {
              insert(kill_text);
            }
          } else if (e.which == 86) { //CTRL+V
            paste();
            return true;
          } else if (e.which == 75) { //CTRL+K
            if (position == 0) {
              kill_text = command;
              self.set('');
            } else if (position != command.length) {
              kill_text = command.slice(position);
              set(command.slice(0, position));
            }
          } else if (e.which == 85) { // CTRL+U
            if (command != '' && position != 0) {
              kill_text = command.slice(0, position);
              self.set(command.slice(position, command.length));
              self.position(0);
            }
          } else if (e.which == 17) { //CTRL+TAB switch tab
            return false;
          }
        }
      } else {
        return true;
      }
      return false;
    }
  }

  var history_list = new List<HistoryManager>();
  String name(String str) {
    if(str != '') {
      _name = str;
      bool enabled = history && history.enabled() || !history;
      history = new HistoryManager(str, historySize);
      if (!enabled) {
        history.disable();
      }
    }
    return _name;
  }
  void set(String str, bool stay) {
    if(str != '') {
      command = str;
      if(!stay) {
        _position = command.length;
      }
      redraw();
      if(_options.containsKey('onCommandChange') && _options['onCommandChange'] is Function) {
        _options['onCommandChange'](command);
      }
    }
  }
  void insert(String str, {bool stay: true}) {
    if (position == command.length) {
      command += str;
    } else if (position == 0) {
      command = str + command;
    } else {
      command = command.substring(0, position) +
      string + command.substring(position);
    }
    if (!stay) {
      position += string.length;
    }
    redraw();
    if(_options.containsKey('onCommandChange') && _options['onCommandChange'] is Function) {
      _options['onCommandChange'](command);
    }
  }
  String get() {
    return command;
  }

  List commands(List _commands) {
    if (_commands) {
      _options['commands'] = _commands;
    }
    return _commands;
  }

  void destroy() {
    window.removeEventListener('.cmd');
    _cursor.nextElementSibling.remove();
    _cursor.previousElementSibling.remove();

    _root.querySelector('.prompt').remove();
    clip.remove();

    _root.classes.remove('cmd');
    // FIXME removeData??
    self.removeClass('cmd').removeData('cmd');
  }

  void prompt(dynamic user_prompt) {
    if (user_prompt == undefined) {
      return _prompt;
    } else {
      if (user_prompt is String || user_prompt is Function) {
        _prompt = user_prompt;
      } else {
        throw 'prompt must be a function or string';
      }
      draw_prompt();
      // we could check if command is longer then numchars-new prompt
      redraw();
    }
  }
  num position(num n) {
    if (n is num) {
      _position = n < 0 ? 0 : n > command.length ? command.length : n;
      redraw();
    }
    return _position;
  }

  void visible() {
    _root.style.visibility = 'visible';
    redraw();
    draw_prompt();
  }

  void show() {
    _root.hidden(false);
    redraw();
    draw_prompt();
  }

  void resize(num n) {
    if(n) {
      num_chars = n;
    } else {
      change_num_chars();
    }
    redraw();
  }
  void enable() {
    enabled = true;
    animation(true);
  }

  void disable() {
    enabled = false;
    animation(false);
  }

  bool mask(bool display) {
    _mask = display;
    redraw();

    return _mask;
  }

}

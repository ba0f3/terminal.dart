part of terminal;

class Interpreter {

}

class Terminal {
  Map<String, dynamic> defaultSettings = {
      'prompt': '> ',
      'history': true,
      'exit': true,
      'clear': true,
      'enabled': true,
      'historySize': 60,
      'checkArity': true,
      'exceptionHandler': null,
      'cancelableAjax': true,
      'processArguments': true,
      'linksNoReferrer': false,
      'login': null,
      'outputLimit': -1,
      'onAjaxError': null,
      'onRPCError': null,
      'completion': false,
      'historyFilter': null,
      'onInit': noop,
      'onClear': noop(),
      'onBlur': noop(),
      'onFocus': noop(),
      'onTerminalChange': noop(),
      'onExit': noop(),
      'keypress': noop(),
      'keydown': noop(),
  };

  Terminal() {
  }

  bool valid_color (String color) {
    return color_hex_re.hasMatch(color) > 0 || color_names.contains('color');
  }

  bool have_formatting(String str) {
    return format_re.hasMatch(str);
  }

  bool is_formatting(String str) {
    return format_full_re.hasMatch(str);
  }

  List<String> format_split(String str) {
    return str.split(format_split_re);
  }

  split_equal(String str, int length) {
    bool formatting = false;
    bool in_text = false;
    num braket = 0;
    String prev_format = '';
    List result = [];
    // add format text as 5th paramter to formatting it's used for
    // data attribute in format function
    List<String> arr = str.replaceAllMapped(format_re, (Match match){
      String format = match.group(1);
      String text = match.group(2);
      int semicolons_count = ';'.allMatches(format).length;
      String semicolons;
      // missing semicolons
      if (semicolons_count == 2) {
        semicolons = ';;';
      } else if (semicolons_count == 3) {
        semicolons = ';';
      } else {
        semicolons = '';
      }
      // return '[[' + format + ']' + text + ']';
      // closing braket will break formatting so we need to escape those using
      // html entity equivalent
      return '[[' + format + semicolons + text.replaceAll(new RegExp(r'/\\\]/'), '&#93;').replaceAll(new RegExp(r'/\n/'), '\\n') + ']' + text + ']';
    }).split(new RegExp(r'/\n/'));
    // ----------------- CONTINUE HERE
    for (var i = 0, len = array.length; i < len; ++i) {
      if (array[i] === '') {
        result.push('');
        continue;
      }
      var line = array[i];
      var first_index = 0;
      var count = 0;
      for (var j=0, jlen=line.length; j<jlen; ++j) {
        if (line[j] === '[' && line[j+1] === '[') {
          formatting = true;
        } else if (formatting && line[j] === ']') {
          if (in_text) {
            formatting = false;
            in_text = false;
          } else {
            in_text = true;
          }
        } else if ((formatting && in_text) || !formatting) {
          if (line[j] === '&') { // treat entity as one character
            var m = line.substring(j).match(/^(&[^;]+;)/);
            if (!m) {
            // should never happen if used by terminal, because
            // it always calls $.terminal.encode before this function
            throw "Unclosed html entity in line " + (i+1) + ' at char ' + (j+1);
            }
            j+=m[1].length-2; // because continue adds 1 to j
            // if entity is at the end there is no next loop - issue #77
            if (j === jlen-1) {
            result.push(output_line + m[1]);
            }
            continue;
          } else if (line[j] === ']' && line[j-1] === '\\') {
          // escape \] counts as one character
          --count;
          } else {
          ++count;
          }
          }
          if (count === length || j === jlen-1) {
          var output_line = line.substring(first_index, j+1);
          if (prev_format) {
          output_line = prev_format + output_line;
          if (output_line.match(']')) {
          prev_format = '';
          }
          }
          first_index = j+1;
          count = 0;
          // Fix output_line if formatting not closed
          var matched = output_line.match(format_re);
          if (matched) {
          var last = matched[matched.length-1];
          if (last[last.length-1] !== ']') {
          prev_format = last.match(format_begin_re)[1];
          output_line += ']';
          } else if (output_line.match(format_last_re)) {
          var line_len = output_line.length;
          var f_len = line_len - last[last.length-1].length;
          output_line = output_line.replace(format_last_re, '');
          prev_format = last.match(format_begin_re)[1];
          }
          }
          result.push(output_line);
          }
          }
          }
          return result;
          },
}

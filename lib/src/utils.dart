part of terminal;

/**
 * Implement of Jquery.noop().
 * @see http://api.jquery.com/jquery.noop/
 */
void noop() {}

/**
 * Split string to array of strings with the same length
 */
List<String> str_parts(String str, int length) {
  var result = new List<String>();
  int len = str.length;
  if (len < length) {
    result.add(str);
    return result;
  }
  for (int i=0; i<len; i+=length) {
    int endIndex = i+length;
    if(endIndex > len)
      endIndex = len;
    result.add(str.substring(i, endIndex));
  }
  return result;
}

int count_substring(String str, String search) {
  return search.allMatches(str).length;
}

DivElement div(String str) {
  return new DivElement()..setInnerHtml(Terminal.encode(str));
}

int skipFormattingCount(String str) {
  var div = new DivElement();
  div.setInnerHtml(Terminal.strip(str));
  return div.text.length;
}

int formattingCount(String str) {
  return str.length - skipFormattingCount(str);
}


bool supportAnimations() {
  var elm = new DivElement();
  return elm.style.supportsProperty('animationName');
}

Map<String, Object> processCommand(String str, Function fn) {
  RegExp re = new RegExp("/^\s+|\s+\$/g");
  List<String> args = str.replaceAll(re, '').split(new RegExp('(\s+)'));
  String rest = str.replaceAll(new RegExp('^[^\s]+\s*'), '');

  return {
    'name': args[0],
    'args': fn(rest),
    'rest': rest
  };
}

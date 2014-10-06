import 'dart:html';
import 'terminal.dart';

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
  int index = 0;
  int count =0;
  while(index != -1){
    index = str.indexOf(search,index);
    if( index != -1){
      count++;
      index+=search.length;
    }
  }
  return count;
}

DivElement div(String str) {
  return new DivElement()..setInnerHtml(Terminal.encode(str));
}

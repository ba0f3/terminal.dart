//import 'package:sprintf/sprintf.dart' show sprintf;

import 'utils.dart';

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
}

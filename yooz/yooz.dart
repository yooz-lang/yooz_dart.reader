library yooz;
import 'dart:math';
import 'createRegex.dart';

class Parser {
  final List<Map<String, dynamic>> _patterns = [];
  final Map _patternsif = {};
  List _if_idf  = [];
  final Map<String, String> _variables = {}; 
  final Random _random = Random();
  List _spantext = []; 
  String _Subject = ''; 
  String _Subjectname = '';
  String lastMessage = ''; 
  String TextError = 'متاسفم، نمی‌توانم پاسخ دهم.'; 
  List _pronouns = [];
  List _Verbs = []; 
  bool _Bpronouns = false;
  bool _bVerbs = false;
  Map _fixanswer = {}; 
  final List<Map> _addtonextword = [];
  bool _IF = false;
  bool _Trueif = false;
  bool _Trueelse = false;
  bool _Trueelseif = false;
  bool _textg = false;

  void loadPatterns(String patternString) {
    final lines = patternString.split('\n');
    String? currentPattern;
    List<String>? currentResponses;
    for (var line in lines) {
      line = line.trim();

      if (line.startsWith('!') || line.startsWith('[') && line.contains(']') && line.contains(':')) {

        // add in if
        if (line.startsWith('[') && line.contains(']')) {
          _Trueif = true;
          _IF = true;
          _patternsif.addAll({'add-if':line.replaceAll('[', '').replaceAll(']', '').replaceAll(':', '').split('>')[1].split(' ')[1]});
        }
        
        // add in else if
        if (line.contains('!') && line.contains('[')) {
          _Trueelseif = true;
          _patternsif.addAll({'add-else-if':line.replaceAll('[', '').replaceAll(']', '').replaceAll(':', '').replaceAll('!', '').split('>')[1].split(' ')[1]});
          
        }
      }

      // else
      if (line.startsWith('!') && line.endsWith(':') && !line.contains(']')) _Trueelse = true;

      // The next word method
      if(line.contains('[') && line.contains(']') && line.contains('{') && line.contains('}')){
        // final RegExp regex = RegExp(r'\{(.*?)\}');
        final matches = RegExp(r'\{(.*?)\}').allMatches(line);
        List<Map<String, String>> results = [];
        for (var match in matches) {
          String content = match.group(1)!.trim();
          final numberRegex = RegExp(r'\[(.*?)\]');
          final numberMatch = numberRegex.firstMatch(content);
          String number = numberMatch != null ? numberMatch.group(1)!.trim() : '';
          String output = content.replaceAll(RegExp(r'\[.*?\]'), '');
          output = output.replaceAll(RegExp(r'\s+'), ' ').trim();
          List<String> parts = output.split(' > ');
           if (parts.length == 2) {
            _addtonextword.add({
              'number':number,
              'text': parts[0],
              'end': parts[1],
            });
          }
        }
      }

      // Save variables method
      if (line.startsWith('#')) {
        final parts = line.substring(1).split(':');
        if (parts.length == 2) {
          _variables[parts[0].trim()] = parts[1].trim();
        }
      }

      // The method of identifying the words of Asafa
      if (line.startsWith('-') && line.contains('{') && line.contains('}'))  _spantext = line.replaceAll('}', '').replaceAll('{', '').replaceAll('-', '').trim().split(',');

      // Fixed response method
      if (line.startsWith('{') && line.contains("}") && line.contains('->')) {
        var a = line.replaceAll('{', '').replaceAll('}', '').split('->');
        _fixanswer[a[0]] = a[1];
      }

      // The subject save method
      if (line.startsWith('=') && line.contains(':')) {
        final parts = line.substring(1).split(':');
        if (parts.length == 2) {
          _Subject = parts[1].trim();
        }
      }

      // Text method after each answer
      if (line.startsWith('+') && line.contains('(') && line.contains(')')) lastMessage = line.replaceAll('(', '').replaceAll(')', '').replaceAll('+', '').trim();

      if (!line.startsWith('-') && line.endsWith('}') && line.contains('{')) {
        if (line.startsWith('ضمایر')) {
          final parts = line.split('{');
          final key = parts[0].trim();
          final valuesString = parts[1].replaceAll('}', '').trim();
          final values = valuesString.split('،').map((s) => s.trim()).toList();
          if (key == 'ضمایر') {
            _Bpronouns = true;
            _pronouns.addAll(values);
          } else if (line.startsWith('افعال')) {
            final parts = line.split('{');
            final key = parts[0].trim();
            final valuesString = parts[1].replaceAll('}', '').trim();
            final values =
                valuesString.split('،').map((s) => s.trim()).toList();
            if (key == 'افعال') {
              _bVerbs = true;
              _Verbs.addAll(values);
            }
          }
        }
      }

      // Save questions
      if (line.startsWith('+')) {
        if (currentPattern != null && currentResponses != null) {
          _patterns
              .add({'pattern': currentPattern, 'responses': currentResponses});
        }
        currentPattern = line.substring(1).trim();
        currentResponses = [];
      }
      if (line.contains('}') && line.contains('{')) {
        if (line.contains(',')) {
          var line1 = line.substring(1).trim().replaceAll('{', '').replaceAll('}', '').split(',');
          for (var tt in line1) {
           _if_idf.add(tt);
          }
        }
      }

      // Efficient and saved questions section
      if (line.startsWith('-')) {
        if (_Trueif == true) {
          _patternsif.addAll({'text-if':line.substring(1).trim()});
          _Trueif = false;
        }else if (_Trueelseif == true) {
          _patternsif.addAll({'text-else-if':line.substring(1).trim()});
          _Trueelseif = false;
        }else if(_Trueelse == true){
           _patternsif.addAll({'text-else':line.substring(1).trim()});
          _Trueelse = false;
        }
        if (line.contains(_Subjectname)) {
          line = line.replaceAll('=', '').replaceAll('موضوع', _Subject);
        }

        Iterable<Match> matches = RegExp(r'#\w+').allMatches(line);
        for (var rr in matches) {
            if (_variables.containsKey(rr.group(0)?.replaceAll('#', ''))) {
              currentResponses?.add(line.substring(1).trim().replaceAll(rr.group(0)!, _variables[rr.group(0)?.replaceAll('#', '')]!));
            }
        }
          var responses =
            line.substring(1).trim().split('_').map((s) => s.trim()).toList();
            currentResponses?.addAll(responses);
      }
    }

    if (currentPattern != null && _IF == true) {
      _patterns.add({'pattern': currentPattern, 'responses': _patternsif});
    }else if (currentPattern != null && currentResponses != null) {
      if (_if_idf.isNotEmpty) {
        for (var ttt in _if_idf) {
           _patterns.add({'pattern': ttt, 'responses': currentResponses});
        }
      }else{
        _patterns.add({'pattern': currentPattern, 'responses': currentResponses});
      }
    }

  }

  String parse(String input) {
    // check and change text in input
    for (var fix in input.split(' ')) {
      if (_fixanswer.containsKey(fix)) {
        input = input.replaceAll(fix[0], fix[1]);
      }
    }

    // check and add text in end input
    for (var Eadd in _addtonextword) {
     if (Eadd['text'] == input && num.parse(Eadd['number']) > 0.5) {
       input = input +' '+ Eadd['end'];
     }
    }

    // The method of removing adjectives
    for (var word in _spantext) {
      input = input.replaceAll(RegExp('\\b${RegExp.escape(word)}\\b'), '');
    }

    // Examining pronouns
    if (_bVerbs || _Bpronouns) {
      for (var pronoun in _pronouns) {
        if (input.contains(pronoun)) {
          return 'شما از ضمایر استفاده کردین\n' + lastMessage;
        }
      }
      for (var verbs in _Verbs) {
        if (input.contains(verbs)) {
          return 'شما از افعال استفاده کردین\n' + lastMessage;
        }
      }
    }

    // if else
    if (_IF == true) {
      Iterable<Match> matches = RegExp(r'\d+').allMatches(input);
      List<int> numbers = matches.map((match) => int.parse(match.group(0)!)).toList();
      for (var number in numbers) {
        num aif = num.parse(_patternsif['add-if']);
        num aelseif = num.parse(_patternsif['add-else-if']);
        if(number > aif){
          return _patternsif['text-if'] + "\n" + lastMessage;
        }else if(number > aelseif){
          return _patternsif['text-else-if'] + "\n" + lastMessage ;
        }else{
          return _patternsif['text-else'] + "\n" + lastMessage;
        }
      }
    }else{
      for (var entry in _patterns) {
        final pattern = entry['pattern'] as String;
        final responses = entry['responses'] as List<String>;

        final regex = createRegex(pattern);
        final match = regex.firstMatch(input);
        if (match != null) {
          return _generateResponse(responses, match);
        }
      }
    }
    return TextError;
  }

  String _generateResponse(List<String> responses, RegExpMatch match) {
    // Choose a random answer
    final response = responses[_random.nextInt(responses.length)];
    String generatedResponse = response;
    for (var i = 0; i < match.groupCount; i++) {
      generatedResponse =
          generatedResponse.replaceAll('*', match.group(i + 1)!);
    }

    if (generatedResponse.endsWith('!>')) {
      generatedResponse =
          generatedResponse.substring(0, generatedResponse.length - 2).trim();
      List<String> variableKey1 =
          match.group(0)!.split(" ");
      for (var variableKey in variableKey1) {
        if (variableKey != null && _variables.containsKey(variableKey)) {
          generatedResponse +=
              " " + _variables[variableKey]!;
        }
      }
    }
    return generatedResponse + "\n" + lastMessage;
  }
}

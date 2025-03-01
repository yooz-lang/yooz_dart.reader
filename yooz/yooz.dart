library yooz;

import 'dart:math';
import 'createRegex.dart';

class Parser {
  List<Map> _patterns = [];
  List _if_idf  = []; // --> {iran, tehran}
  Map<String, String> _variables = {}; // save variables
  // Random _random = Random();
  List _spantext = []; // spam text for delete in input
  Map<String, String> _subject = {}; // subject key and value
  Map _Category = {};
  List _TCategory = [];
  bool _BCategory = false;
  String lastMessage = "\n"; // text for last message 
  String TextError = 'متاسفم، نمی‌توانم پاسخ دهم.'; // text Error
  Map _fixanswer = {}; // edit and writing text
  List<Map> _addtonextword = []; // add text in end text
  Map _patternsif = {};
  bool _IF = false;
  bool _Trueif = false;
  bool _Trueelse = false;
  bool _Trueelseif = false;

  void loadPatterns(String patternString) {
    final lines = patternString.split('\n');
    String? currentPattern;
    List<String>? currentResponses;
    for (var line in lines) {
      line = line.trim().toLowerCase();
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
        }else{
          _patternsif.addAll({'add-else-if':"9999199"});
        }
      }

      // else
      if (line.startsWith('!') && line.endsWith(':') && !line.contains(']')) _Trueelse = true;

      // The next word method
      if(line.contains('[') && line.contains(']') && line.contains('{') && line.contains('}')){
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
      if (line.startsWith('-') && line.contains('{') && line.contains('}')) {
        _spantext = line.replaceAll('}', '').replaceAll('{', '').replaceAll('-', '').trim().split(',');
      }

      // Fixed response method
      if (line.startsWith('{') && line.contains("}") && line.contains('->')) {
        var a = line.replaceAll('{', '').replaceAll('}', '').split('->');
        _fixanswer[a[0].trim()] = a[1].trim();
      }

      // The subject save method
      if (line.startsWith('=') && line.contains(':')) {
        List parts = line.substring(1).split(':');
        if (line.substring(1).split(':').length == 2) {
           _subject[parts[0].trim()] = parts[1].trim();
        }
      }

      // Text method after each answer
      if (line.startsWith('+') && line.contains('(') && line.contains(')')) lastMessage = lastMessage+line.replaceAll('(', '').replaceAll(')', '').replaceAll('+', '').trim();

      // Category
      if (!line.startsWith('-') && !line.startsWith('{') && !line.startsWith('+') && !line.startsWith('&') && !line.startsWith('#') && !line.startsWith('*') && line.endsWith('}') && line.contains('{')) {
        line = line.replaceAll('}', "");
        _BCategory = true;
        if (line.contains(',')) {
          _Category[line.split('{')[0].trim()] = line.split('{')[1].split(',');
        }else if(line.contains('،')){
          _Category[line.split('{')[0].trim()] = line.split('{')[1].split('،');
        }
      }

      // Save questions
      if (line.startsWith('+')) {
        currentPattern = line.substring(1).trim();
        currentResponses = [];
      }

      if (line.contains('_')) {
          var responses =
            line.substring(1).trim().split('_').map((s) => s.trim()).toList();
            currentResponses?.addAll(responses);
        }
      

      if (line.contains('&')) {
          for (var element in _Category.keys) {
            if (element.toString().trim() == line.split('&')[1].trim().toString()) {
              for (var element1 in _Category[element]) {
                _TCategory.add(element1.toString().trim());
              }
            }
          }
      }

      if (line.contains('}') && line.contains('{') && !line.startsWith('-')) {
        List line1 = [];
        if (line.contains(',')) {
          line1 = line.substring(1).trim().replaceAll('{', '').replaceAll('}', '').split(',');
        }else if(line.contains('،')){
          line1 = line.substring(1).trim().replaceAll('{', '').replaceAll('}', '').split('،');
        }
        for (var tt in line1) {
               _if_idf.add(tt.trim());
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
          _Trueelse = false;}
        if (_IF == false && !line.contains('_') && !line.contains('#') && !line.contains('&') && !line.contains('=') && currentPattern != null && currentResponses != null && _if_idf.isEmpty) {
        _patterns.add({'pattern': currentPattern, 'responses': [line.substring(1).trim()]});
     }
        if (line.contains('=')) {    
          for (var element in _subject.keys) {
            currentResponses?.add(line.substring(1).replaceAll('=$element', _subject[element]!).trim());
            _patterns.add({'pattern': currentPattern, 'responses': currentResponses});
          }
        }
        if (_BCategory) {
          for (var element in _TCategory) {
            _patterns.add({'pattern': currentPattern!.replaceAll('&'+currentPattern.split('&')[1].trim(), element), 'responses': [line.substring(1).trim()]});
            }
        }
        if (_if_idf.isNotEmpty) {
          for (var element in _if_idf) {
            _patterns.add({'pattern': element.trim(), 'responses': [line.substring(1).trim()]});
          }
        }
        if (line.contains('#')) {
          Iterable<Match> matches = RegExp(r'#\w+').allMatches(line);
          for (var rr in matches) {
              if (_variables.containsKey(rr.group(0)?.replaceAll('#', ''))) {
                currentResponses?.add(line.substring(1).trim().replaceAll(rr.group(0)!, _variables[rr.group(0)?.replaceAll('#', '')]!));
                _patterns.add({'pattern': currentPattern, 'responses': currentResponses});
              }
          }
        }
        
      }
    }
    
    if (currentPattern != null && _IF == true) {
      _patterns.add({'pattern': currentPattern, 'responses': _patternsif});
    }else{
      _patterns.add({'pattern': currentPattern, 'responses': currentResponses});
    }
  }

  String parse(String input) {
    // The method of removing adjectives
    if (_spantext.isNotEmpty) {
      List _textspam = [];
      for (var word in _spantext) {
        for (var elementinput in input.split(' ')) {
          for (var element in _spantext) {
            if (element.trim() == elementinput.trim()) {
              if (!_textspam.contains(element)) {
                _textspam.add(element); 
              }
            }
          }
        }
      }
      for (var elementspam in _textspam) {
        input = input.replaceAll(elementspam.trim(), '').trim();
        input = input.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    }

    // check and change text in input
    for (var fix in input.split(' ')) {
      if (_fixanswer.containsKey(fix)) {
        input = input.replaceAll(fix,_fixanswer.values.toString().replaceAll('(','').replaceAll(')','')).trim();
      }
    }

    // check and add text in end input
    for (var Eadd in _addtonextword) {
     if (Eadd['text'] == input && num.parse(Eadd['number']) > 0.5) {
       input = input +' '+ Eadd['end'];
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
        }else if(number > aelseif && aelseif != "9999199"){
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
    print(responses);
    final response = responses[Random().nextInt(responses.length)];
    String generatedResponse = response;
    for (var i = 0; i < match.groupCount; i++) {
      generatedResponse =
          generatedResponse.replaceAll('*', match.group(i + 1)!);
    }
    if (generatedResponse.endsWith('!>') || generatedResponse.contains('!>')) {
      generatedResponse =
          generatedResponse.substring(0, generatedResponse.length - 2).trim();
      List<String> variableKey1 =
          match.group(0)!.split(" ");
      for (var variableKey in variableKey1) {
        if (_variables.containsKey(variableKey)) {
          generatedResponse +=
              " " + _variables[variableKey]!;
        }
      }
    }
    if (lastMessage == "\n") {
      return generatedResponse;
    }else{
      return generatedResponse + lastMessage;
    }
  }
}

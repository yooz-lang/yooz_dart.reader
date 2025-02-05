library yooz;

import 'dart:math';
import 'createRegex.dart';

class Parser {
  List<Map> _patterns = [];
  Map _patternsif = {};
  List _if_idf  = [];
  Map<String, String> _variables = {}; // save variables
  Random _random = Random();
  List _spantext = []; // spam text for delete in input
  Map<String, String> _subject = {}; // subject key and value
  Map _Category = {};
  List _TCategory = [];
  bool _BCategory = false;
  String lastMessage = "\n"; // text for last message 
  String TextError = 'متاسفم، نمی‌توانم پاسخ دهم.'; // text Error
  Map _fixanswer = {};
  List<Map> _addtonextword = []; // add text in end text
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
      if (line.startsWith('-') && line.contains('{') && line.contains('}'))  _spantext = line.replaceAll('}', '').replaceAll('{', '').replaceAll('-', '').trim().split(',');

      // Fixed response method
      if (line.startsWith('{') && line.contains("}") && line.contains('->')) {
        var a = line.replaceAll('{', '').replaceAll('}', '').split('->');
        _fixanswer[a[0]] = a[1];
      }

      // The subject save method
      if (line.startsWith('=') && line.contains(':')) {
        List parts = line.substring(1).split(':');
        if (parts.length == 2) {
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

      if (line.contains('&')) {
          for (var element in _Category.keys) {
            // print(element);
            if (element.toString().trim() == line.split('&')[1].trim().toString()) {
              for (var element1 in _Category[element]) {
                _TCategory.add(element1.toString().trim());
              }
            }
          }
      }

      if (line.contains('}') && line.contains('{')) {
        if (line.contains(',')) {
          var line1 = line.substring(1).trim().replaceAll('{', '').replaceAll('}', '').split(',');
          for (var tt in line1) {
           _if_idf.add(tt);
          }
        }else if(line.contains('،')){
          var line1 = line.substring(1).trim().replaceAll('{', '').replaceAll('}', '').split(',');
            for (var tt in line1) {
               _if_idf.add(tt);
            }
        }
        if (currentPattern != null && currentResponses != null) {
          _patterns
              .add({'pattern': currentPattern, 'responses': currentResponses});
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

        if (line.contains('=')) {            
            Iterable<Match> matches = RegExp(r"=\s*(\w+)").allMatches(line.substring(1).trim());
            for (Match match in matches) {
              String word = match.group(1)!;
              if (_subject.containsKey(word)) {
                currentResponses?.add(line.substring(1).trim().replaceAll(match.group(0)!, _subject[word]!));
              }
            }
        }

        if (_BCategory) {
          for (var element in _TCategory) {
            _patterns.add({'pattern': currentPattern!.replaceAll('&'+currentPattern.split('&')[1].trim(), element), 'responses': [line.substring(1).trim()]});
            }
        }

        if (line.contains('#')) {
          Iterable<Match> matches = RegExp(r'#\w+').allMatches(line);
          for (var rr in matches) {
              if (_variables.containsKey(rr.group(0)?.replaceAll('#', ''))) {
                currentResponses?.add(line.substring(1).trim().replaceAll(rr.group(0)!, _variables[rr.group(0)?.replaceAll('#', '')]!));
              }
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
    // The method of removing adjectives
    if (_spantext.isNotEmpty) {
      for (var word in _spantext) {
        input = input.replaceAll(word.trim(), '').trim();
      }
    }

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


    

    // if else
    if (_IF == true) {
      Iterable<Match> matches = RegExp(r'\d+').allMatches(input);
      List<int> numbers = matches.map((match) => int.parse(match.group(0)!)).toList();
      for (var number in numbers) {
        num aif = num.parse(_patternsif['add-if']);
        num aelseif = num.parse(_patternsif['add-else-if']);
        if(number > aif && aif != null){
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
    if (lastMessage == "\n") {
      return generatedResponse;
    }else{
      return generatedResponse + lastMessage;
    }
    
  }
}

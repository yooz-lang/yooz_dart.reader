library yooz;

import 'dart:io';
import 'dart:math';

class Parser {
  final List<Map<String, dynamic>> patterns = [];
  final Map<String, String> variables = {};
  final Random _random = Random();
  List spantext = [];
  String Subject = ''; 
  String Subjectname = ''; 
  String lastMessage = ''; 
  String TextError = 'متاسفم، نمی‌توانم پاسخ دهم.'; 
  List pronouns = []; 
  List Verbs = [];
  bool Bpronouns = false;
  bool bVerbs = false;
  Map fixanswer = {}; 
  final List<Map> addtonextword = []; // add text in end text

  void loadPatterns(String patternString) {
    final lines = patternString.split('\n');
    String? currentPattern;
    List<String>? currentResponses;

    for (var line in lines) {
      line = line.trim();

      // The next word method
      if(line.contains('[') && line.contains(']') && line.contains('{') && line.contains('}')){
        final RegExp regex = RegExp(r'\{(.*?)\}');
        final matches = regex.allMatches(line);
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
            addtonextword.add({
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
          variables[parts[0].trim()] = parts[1].trim();
        }
      }
      // Fixed response method
      if (line.startsWith('{') && line.contains("}") && line.contains('->')) {
        var a = line.replaceAll('{', '').replaceAll('}', '').split('->');
        fixanswer[a[0]] = a[1];
      }
      // The subject save method
      if (line.startsWith('=') && line.contains(':')) {
        final parts = line.substring(1).split(':');
        if (parts.length == 2) {
          Subject = parts[1].trim();
        }
      }
      // Text method after each answer
      if (line.startsWith('+') && line.contains('(') && line.contains(')')) {
        lastMessage = line
            .replaceAll('(', '')
            .replaceAll(')', '')
            .replaceAll('+', '')
            .trim();
      }
      // The method of identifying the words of Asafa
      if (line.startsWith('-') && line.contains('{') && line.contains('}')) {
        spantext = line
            .replaceAll('}', '')
            .replaceAll('{', '')
            .replaceAll('-', '')
            .trim()
            .split('،');
      }
      if (!line.startsWith('-') && line.endsWith('}') && line.contains('{')) {
        if (line.startsWith('ضمایر')) {
          final parts = line.split('{');
          final key = parts[0].trim();
          final valuesString = parts[1].replaceAll('}', '').trim();
          final values = valuesString.split('،').map((s) => s.trim()).toList();
          if (key == 'ضمایر') {
            Bpronouns = true;
            pronouns.addAll(values);
          } else if (line.startsWith('افعال')) {
            final parts = line.split('{');
            final key = parts[0].trim();
            final valuesString = parts[1].replaceAll('}', '').trim();
            final values =
                valuesString.split('،').map((s) => s.trim()).toList();
            if (key == 'افعال') {
              bVerbs = true;
              Verbs.addAll(values);
            }
          }
        }
      }
      if (line.startsWith('+')) {
        if (currentPattern != null && currentResponses != null) {
          patterns
              .add({'pattern': currentPattern, 'responses': currentResponses});
        }
        currentPattern = line.substring(1).trim();
        currentResponses = [];
      }
      // Random answer method
      if (line.startsWith('-')) {
        if (line.contains(Subjectname)) {
          line = line.replaceAll('=', '').replaceAll('موضوع', Subject);
        }
        var responses =
            line.substring(1).trim().split('_').map((s) => s.trim()).toList();
        currentResponses?.addAll(responses);
      }
    }

    if (currentPattern != null && currentResponses != null) {
      patterns.add({'pattern': currentPattern, 'responses': currentResponses});
    }
  }

  String parse(String input) {

    // check and change text in input
    for (var fix in input.split(' ')) {
      if (fixanswer.containsKey(fix)) {
        input = input.replaceAll(fix[0], fix[1]);
      }
    }

    // check and add text in end input
    for (var Eadd in addtonextword) {
     if (Eadd['text'] == input && num.parse(Eadd['number']) > 0.5) {
       input = input +' '+ Eadd['end'];
     }
    }

    // The method of removing adjectives
    for (var word in spantext) {
      input = input.replaceAll(RegExp('\\b${RegExp.escape(word)}\\b'), '');
    }
    input = input.replaceAll(RegExp(r'\s+'), ' ').trim();

    // examining variables
    for (var entry in patterns) {
      final pattern = entry['pattern'] as String;
      var responses = entry['responses'] as List<String>;
      for (var test in responses) {
        test = test.replaceAll('#', '');
        if (variables.containsKey(test)) {
          return variables[test]! + " " + lastMessage;
      }
      }
    }

    // Examining pronouns
    if (bVerbs || Bpronouns) {
      for (var pronoun in pronouns) {
        if (input.contains(pronoun)) {
          return 'شما از ضمایر استفاده کردین\n' + lastMessage;
        }
      }
      for (var verbs in Verbs) {
        if (input.contains(verbs)) {
          return 'شما از افعال استفاده کردین\n' + lastMessage;
        }
      }
    }

    for (var entry in patterns) {
      final pattern = entry['pattern'] as String;
      final responses = entry['responses'] as List<String>;
      final regex = _createRegex(pattern);
      final match = regex.firstMatch(input);
      if (match != null) {
        return _generateResponse(responses, match);
      }
    }

    return TextError;
  }

  RegExp _createRegex(String pattern) {
    final escapedPattern = RegExp.escape(pattern).replaceAll(r'\*', r'([^ ]+)');
    return RegExp('^$escapedPattern\$');
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
        if (variableKey != null && variables.containsKey(variableKey)) {
          generatedResponse +=
              " " + variables[variableKey]!;
        }
      }
    }
    return generatedResponse + "\n" + lastMessage;
  }
}

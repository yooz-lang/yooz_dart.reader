import 'yooz/yooz.dart';

void main(){
    final parser = Parser();
    
    String patternString = '''

    #msg:Im yooz bot.

    { [0.7] Hi > yooz }
    
    (    
        + Hi yooz
        - #msg
    )
    
    ''';
    
    parser.TextError = "I don't understand";
    
    parser.loadPatterns(patternString);
    
    print(parser.parse("Hi"));

}

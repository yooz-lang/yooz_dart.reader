RegExp createRegex(String pattern) {
  final escapedPattern = RegExp.escape(pattern).replaceAll(r'\*', r'([^ ]+)');
  return RegExp('^$escapedPattern\$');
}
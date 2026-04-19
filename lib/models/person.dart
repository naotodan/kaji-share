import 'package:flutter/material.dart';

enum Person {
  husband('夫', '👨', Colors.blue),
  wife('妻', '👩', Colors.pink);

  const Person(this.displayName, this.icon, this.color);

  final String displayName;
  final String icon;
  final Color color;
}

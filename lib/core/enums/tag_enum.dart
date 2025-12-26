enum TagType {
  tag("tag"),

  author("va"),

  circle("circle"),

  age("age");

  final String stringValue;

  const TagType(this.stringValue);

  String toApiString() {
    return stringValue;
  }
}
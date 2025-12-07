enum TagType {
  tag("tag"),

  author("va"),

  circle("circle");

  final String stringValue;

  const TagType(this.stringValue);

  String toApiString() {
    return stringValue;
  }
}
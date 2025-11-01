bool isValidEmail(String value) {
  const pattern = r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$';
  return RegExp(pattern).hasMatch(value);
}

bool isValidPassword(String value) {
  return value.length >= 6;
}
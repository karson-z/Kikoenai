class RegisterRequestModel {
  final String name;
  final String password;
  final String recommenderUuid;

  const RegisterRequestModel({
    required this.name,
    required this.password,
    this.recommenderUuid = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'password': password,
    'recommenderUuid': recommenderUuid,
  };

  RegisterRequestModel copyWith({
    String? name,
    String? password,
    String? recommenderUuid,
  }) {
    return RegisterRequestModel(
      name: name ?? this.name,
      password: password ?? this.password,
      recommenderUuid: recommenderUuid ?? this.recommenderUuid,
    );
  }
}
import '../../user/data/services/user_repository.dart';
import '../data/models/user_model.dart';
import 'package:name_app/core/domain/result.dart';

class GetUsersUseCase {
  final UserRepository repository;
  GetUsersUseCase(this.repository);

  Future<Result<List<UserModel>>> call({int? start, int? limit}) => repository.getUsers(start: start, limit: limit);
}
import 'package:flutter/material.dart';
import 'package:name_app/core/common/shared_preferences_service.dart';
import 'package:name_app/features/user/data/models/user_model.dart';

// 直接调用SharedPreferencesService并输出结果
void main() async {
  // 创建SharedPreferencesService实例
  final service = SharedPreferencesService();

  print('=== SharedPreferencesService 实际调用测试 ===');
  print('');
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesService.checkSize(warnThresholdKB: 512); // 默认阈值 512KB
  // 1. 测试保存Token
  print('1. 测试 saveToken:');
  final testToken = 'test-token-${DateTime.now().millisecondsSinceEpoch}';
  final saveTokenResult = await service.saveToken(testToken);
  print('   保存结果: ${saveTokenResult.isSuccess ? '成功' : '失败'}');
  if (saveTokenResult.error != null) {
    print('   错误信息: ${saveTokenResult.error?.message}');
  }
  print('');

  // 2. 测试获取Token
  print('2. 测试 fetchToken:');
  final fetchTokenResult = await service.fetchToken();
  print('   获取结果: ${fetchTokenResult.isSuccess ? '成功' : '失败'}');
  print('   Token值: ${fetchTokenResult.data}');
  if (fetchTokenResult.error != null) {
    print('   错误信息: ${fetchTokenResult.error?.message}');
  }
  print('');

  // 3. 测试保存用户信息
  print('3. 测试 saveUserInfo:');
  final userModel = UserModel(
    uid: 1001,
    nickname: '测试用户',
    account: 'test_account',
    phone: '13800138000',
  );
  final saveUserInfoResult = await service.saveUserInfo(userModel);
  print('   保存结果: ${saveUserInfoResult.isSuccess ? '成功' : '失败'}');
  if (saveUserInfoResult.error != null) {
    print('   错误信息: ${saveUserInfoResult.error?.message}');
  }
  print('');

  // 4. 测试获取用户信息
  print('4. 测试 fetchUserInfo:');
  final fetchUserInfoResult = await service.fetchUserInfo();
  print('   获取结果: ${fetchUserInfoResult.isSuccess ? '成功' : '失败'}');
  if (fetchUserInfoResult.data != null) {
    print('   用户ID: ${fetchUserInfoResult.data?.uid}');
    print('   昵称: ${fetchUserInfoResult.data?.nickname}');
    print('   账号: ${fetchUserInfoResult.data?.account}');
    print('   手机号: ${fetchUserInfoResult.data?.phone}');
  } else {
    print('   用户信息: null');
  }
  if (fetchUserInfoResult.error != null) {
    print('   错误信息: ${fetchUserInfoResult.error?.message}');
  }
  print('');

  // 5. 测试移除用户信息
  print('5. 测试 removeUserInfo:');
  final removeUserInfoResult = await service.removeUserInfo();
  print('   移除结果: ${removeUserInfoResult.isSuccess ? '成功' : '失败'}');
  if (removeUserInfoResult.error != null) {
    print('   错误信息: ${removeUserInfoResult.error?.message}');
  }
  print('');

  // 6. 测试移除Token
  print('6. 测试 removeToken:');
  final removeTokenResult = await service.removeToken();
  print('   移除结果: ${removeTokenResult.isSuccess ? '成功' : '失败'}');
  if (removeTokenResult.error != null) {
    print('   错误信息: ${removeTokenResult.error?.message}');
  }
  print('');

  // 7. 测试移除所有数据
  print('7. 测试 removeAll:');
  // 先保存一些数据以便测试移除
  await service.saveToken('temp-token-for-remove-all');
  final testUserForRemove = UserModel(
    uid: 1002,
    nickname: '临时用户',
  );
  await service.saveUserInfo(testUserForRemove);

  final removeAllResult = await service.removeAll();
  print('   移除结果: ${removeAllResult.isSuccess ? '成功' : '失败'}');
  if (removeAllResult.error != null) {
    print('   错误信息: ${removeAllResult.error?.message}');
  }
  print('');

  // 验证移除结果
  print('8. 验证 removeAll 后的状态:');
  final afterToken = await service.fetchToken();
  final afterUser = await service.fetchUserInfo();
  print('   Token: ${afterToken.data ?? 'null'}');
  print('   用户信息: ${afterUser.data != null ? '存在' : 'null'}');
  print('');

  print('=== 测试完成 ===');
}

# 测试说明

本目录包含项目的所有单元测试和集成测试。

## 测试结构

测试目录结构与 lib 目录保持一致，便于查找和维护：

```
test/
  ├── features/
  │   └── tag/
  │       └── data/
  │           └── service/
  │               └── tag_repository_test.dart
  ├── mocktail_config.dart
  └── README.md
```

## 运行测试

### 运行所有测试

```bash
flutter test
```

### 运行特定文件的测试

```bash
flutter test test/features/tag/data/service/tag_repository_test.dart
```

### 运行带覆盖率的测试

```bash
flutter test --coverage
```

生成的覆盖率报告将保存在 `coverage/lcov.info` 文件中。

## 使用的测试库

- **flutter_test**: Flutter 官方测试框架
- **mocktail**: 用于创建模拟对象的库，比 mockito 更简洁

## 编写测试的最佳实践

1. **测试分组**: 使用 `group` 函数对相关测试进行分组
2. **测试准备**: 在 `setUp` 中准备测试环境和模拟对象
3. **测试隔离**: 每个测试应该相互独立
4. **模拟依赖**: 对外部依赖（如 API 客户端）进行模拟
5. **全面覆盖**: 测试正常流程、边界条件和错误情况
6. **断言明确**: 使用明确的断言来验证预期结果
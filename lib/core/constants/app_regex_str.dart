/// 正则表达式常量管理类
class RegexPatterns {
  // 私有构造函数，防止实例化
  RegexPatterns._();

  /// 标准作品 ID 格式
  /// 匹配: RJ123456, rj123456, VJ001 (无视大小写)
  /// (?i) = 开启不区分大小写模式
  static const String workId = r'(RJ|BJ|VJ)\d+';

  /// 纯日期格式 (YYYY-MM-DD)
  /// 用于验证文件夹是否是日期归档
  static const String dateFolder = r'^\d{4}-\d{2}-\d{2}$';


}
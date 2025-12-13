import 'package:flutter/material.dart';
import 'package:kikoenai/core/service/cache_service.dart';

/// 普通 BottomSheet 缓存管理弹窗
Future<void> showCacheManagerSheet(
    BuildContext context, {
      required List<String> boxNames,
    }) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        builder: (_, controller) {
          return FutureBuilder(
            future: _loadCacheInfos(boxNames),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final cacheInfos = snapshot.data!;
              final total = cacheInfos.fold<int>(0, (a, b) => a + b.size);

              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Text(
                      "缓存管理",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      "总缓存大小：${_formatBytes(total)}",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: cacheInfos.length,
                        itemBuilder: (context, index) {
                          final info = cacheInfos[index];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(info.name),
                              subtitle:
                              Text("大小：${_formatBytes(info.size)}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await CacheService.instance
                                      .clearBoxFile(info.name);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                        foregroundColor:
                        Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      onPressed: () async {
                        for (final name in boxNames) {
                          await CacheService.instance.clearBoxFile(name);
                        }

                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("清除全部缓存"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}


/// 读取所有 box 的信息
Future<List<_CacheInfo>> _loadCacheInfos(List<String> boxNames) async {
  final list = <_CacheInfo>[];
  for (final name in boxNames) {
    final s = await CacheService.instance.getBoxFileSize(name);
    list.add(_CacheInfo(name: name, size: s));
  }
  return list;
}

/// 缓存信息对象
class _CacheInfo {
  final String name;
  final int size;
  _CacheInfo({required this.name, required this.size});
}

/// 字节格式化
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
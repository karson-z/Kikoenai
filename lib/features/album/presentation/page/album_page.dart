import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:name_app/features/album/presentation/viewmodel/album_view_model.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('专辑详情'),
        centerTitle: true,
      ),
      body: ChangeNotifierProvider(
        create: (_) => AlbumViewModel()..featchAlbums(),
        child: const AlbumContent(),
      ),
    );
  }
}

class AlbumContent extends StatelessWidget {
  const AlbumContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AlbumViewModel>(context);

    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: ${viewModel.error?.message}'),
            ElevatedButton(
              onPressed: () => viewModel.featchAlbums(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (viewModel.albums.isEmpty) {
      return const Center(child: Text('暂无专辑数据'));
    }

    // 为了演示，我们使用第一张专辑数据
    final album = viewModel.albums.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 专辑封面和基本信息
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图片
              album.coverUrl != null
                  ? Image.network(
                      album.coverUrl!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 150,
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.album),
                    ),

              const SizedBox(width: 16),

              // 专辑信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.albumTitle ?? '未知标题',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text('RJ代码: ${album.rjCode ?? '未知'}'),
                    const SizedBox(height: 8),
                    if (album.circleVo != null)
                      Text('社团: ${album.circleVo?.circleName ?? '未知'}'),
                    const SizedBox(height: 8),
                    Text(
                      '创建时间: ${album.createdAt != null ? '${album.createdAt?.year}-${(album.createdAt?.month ?? 0).toString().padLeft(2, '0')}-${(album.createdAt?.day ?? 0).toString().padLeft(2, '0')}' : '未知'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 标签
          const Text(
            '标签:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: album.tags
                    ?.map((tag) => Chip(
                          label: Text(tag.name ?? '未知'),
                          backgroundColor: Colors.blue[100],
                        ))
                    .toList() ??
                [],
          ),

          const SizedBox(height: 24),

          // 作者
          const Text(
            '作者:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: album.authorId
                    ?.map((author) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // 作者头像
                                author.avatar != null
                                    ? CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(author.avatar!),
                                        radius: 30,
                                      )
                                    : const CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.grey,
                                        child: Icon(Icons.person),
                                      ),
                                const SizedBox(width: 12),

                                // 作者信息
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        author.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        author.bio ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '作品数: ${author.workCount ?? 0}',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList() ??
                [],
          ),
        ],
      ),
    );
  }
}

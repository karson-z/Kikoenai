import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';

class PagingProgressIndicator extends StatelessWidget {
  const PagingProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: LottieLoadingIndicator(message: 'loading...', size: 80),
    );
  }
}

class PagingEmptyIndicator extends StatelessWidget {
  const PagingEmptyIndicator({super.key, this.message = '这里什么都没有哦'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 54, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class PagingFirstPageErrorIndicator extends StatelessWidget {
  const PagingFirstPageErrorIndicator({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '加载失败，请检查网络',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class PagingNewPageErrorIndicator extends StatelessWidget {
  const PagingNewPageErrorIndicator({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('加载失败，点击重试'),
        ),
      ),
    );
  }
}

class PagingNoMoreItemsIndicator extends StatelessWidget {
  const PagingNoMoreItemsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '内容もうないから、無理無理(ヾﾉ･∀･`)ﾑﾘﾑﾘ',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

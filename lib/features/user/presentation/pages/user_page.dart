import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../presentation/view_models/user_view_model.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: vm.loading ? null : vm.fetchFirstPage,
                child: const Text('加载用户'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: vm.loading ? null : vm.refresh,
                child: const Text('刷新'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.error != null)
            ErrorBanner(
              message: vm.error!.message,
              onRetry: vm.loading ? null : vm.fetchFirstPage,
            ),
          const SizedBox(height: 8),
          if (vm.loading) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: vm.users.length + (vm.hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  if (index < vm.users.length) {
                    final u = vm.users[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(u.id.toString())),
                      title: Text(u.name),
                      subtitle: Text(u.email),
                    );
                  }
                  // Load more row
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: vm.loading ? null : vm.loadMore,
                        icon: const Icon(Icons.expand_more),
                        label: Text(vm.loading ? '加载中...' : '加载更多'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
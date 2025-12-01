import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/album/data/model/circle.dart';
import 'package:kikoenai/features/album/data/model/tag.dart';
import 'package:kikoenai/features/album/data/model/va.dart';
import 'package:kikoenai/features/category/data/service/category_repository.dart';

import '../../../../../core/service/cache_service.dart';

final circlesProvider = FutureProvider<List<Circle>>((ref) async {
  final cache = CacheService.instance;
  final cached = await cache.getCircleOption();
  if (cached != null && cached.isNotEmpty) {
    final list = cached.map((e) => Circle.fromJson(e)).toList();
    list.sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
    return list;
  }

  final category = ref.read(categoryRepositoryProvider);
  final res = await category.getCircles();
  final list = res.data?.map((c) => Circle.fromJson(c)).toList() ?? [];

  list.sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));

  await cache.saveCircleOption(list.map((c) => c.toJson()).toList());
  return list;
});
final vasProvider = FutureProvider<List<VA>>((ref) async {
  final cache = CacheService.instance;
  final cached = await cache.getVasOption();
  if (cached != null && cached.isNotEmpty) {
    final list = cached.map((e) => VA.fromJson(e)).toList();
    list.sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
    return list;
  }

  final category = ref.read(categoryRepositoryProvider);
  final res = await category.getVas();
  final list = res.data?.map((c) => VA.fromJson(c)).toList() ?? [];

  list.sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));

  await cache.saveVasOption(list.map((c) => c.toJson()).toList());
  return list;
});

final tagsProvider = FutureProvider<List<Tag>>((ref) async {
  final cache = CacheService.instance;
  final cached = await cache.getTagsOption();
  if (cached != null && cached.isNotEmpty) {
    return cached.map((e) => Tag.fromJson(e)).toList();
  }

  final category = ref.read(categoryRepositoryProvider);
  final res = await category.getTags();
  final list = res.data?.map((c) => Tag.fromJson(c)).toList() ?? [];
  list.sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
  await cache.saveTagsOption(list.map((c) => c.toJson()).toList());
  return list;
});
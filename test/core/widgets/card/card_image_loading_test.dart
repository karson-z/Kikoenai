import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';
import 'package:kikoenai/core/widgets/card/work_list_card.dart';
import 'package:kikoenai/core/widgets/image_box/simple_extended_image.dart';
import 'package:kikoenai/core/widgets/loading/lottie_loading.dart';
import 'package:kikoenai/features/album/page/album_detail.dart';

const _loadingImageUrl = 'https://example.invalid/cover.jpg';

void expectSharedLottieLoader(WidgetTester tester) {
  final image = tester.widget<SimpleExtendedImage>(
    find.byType(SimpleExtendedImage),
  );
  expect(image.loadingPlaceholder, isNull);

  final cachedImage = tester.widget<CachedNetworkImage>(
    find.byType(CachedNetworkImage),
  );
  final placeholder = cachedImage.placeholder!(
    tester.element(find.byType(CachedNetworkImage)),
    _loadingImageUrl,
  );
  expect(placeholder, isA<LottieLoadingIndicator>());
}

void main() {
  testWidgets('WorkCard shows the shared Lottie image loader', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 260,
              child: WorkCard(
                id: 1,
                heroTag: 'grid-cover',
                mainCoverUrl: _loadingImageUrl,
              ),
            ),
          ),
        ),
      ),
    );

    expectSharedLottieLoader(tester);
  });

  testWidgets('WorkListCard shows the shared Lottie image loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WorkListCard(
              id: 2,
              heroTag: 'list-cover',
              mainCoverUrl: _loadingImageUrl,
            ),
          ),
        ),
      ),
    );

    expectSharedLottieLoader(tester);
  });

  testWidgets('AlbumCover uses the same shared Lottie image loader', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: AlbumCover(
              heroTag: 'detail-cover',
              mainUrl: _loadingImageUrl,
            ),
          ),
        ),
      ),
    );

    expectSharedLottieLoader(tester);
  });
}

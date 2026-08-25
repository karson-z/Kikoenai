import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/service/file/file_node_library_index.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

void main() {
  group('FileNodeLibraryIndex content source', () {
    test('recognizes a local file index', () {
      final index = FileNodeLibraryIndex(
        flatNodes: [
          FileNode(
            type: NodeType.audio,
            title: 'local.mp3',
            hash: 'local-file',
            mediaStreamUrl: '/media/local.mp3',
            path: '/media/local.mp3',
            folderPath: '/media',
            rootPath: '/media',
            source: NodeSource.localWork,
          ),
        ],
        rootPath: '/media',
        fallbackFolderSource: NodeSource.localWork,
      );

      expect(index.isLocalContent, isTrue);
      expect(index.hasRemoteContent, isFalse);
    });

    test('recognizes a remote file index', () {
      final index = FileNodeLibraryIndex.fromRemoteTree(
        roots: [
          FileNode(
            type: NodeType.audio,
            title: 'remote.mp3',
            hash: 'remote-file',
            mediaStreamUrl: 'https://example.com/remote.mp3',
          ),
        ],
        contentId: const SiteContentId(siteId: 'test-site', remoteId: 'work-1'),
      );

      expect(index.isLocalContent, isFalse);
      expect(index.hasRemoteContent, isTrue);
    });

    test('uses the fallback source for an empty index', () {
      final localIndex = FileNodeLibraryIndex(
        flatNodes: const [],
        rootPath: '/empty',
        fallbackFolderSource: NodeSource.localSingle,
      );
      final remoteIndex = FileNodeLibraryIndex(
        flatNodes: const [],
        rootPath: 'remote://empty',
        fallbackFolderSource: NodeSource.cloudDrive,
      );

      expect(localIndex.isLocalContent, isTrue);
      expect(localIndex.hasRemoteContent, isFalse);
      expect(remoteIndex.isLocalContent, isFalse);
      expect(remoteIndex.hasRemoteContent, isTrue);
    });

    test('keeps remote download support for a mixed index', () {
      final index = FileNodeLibraryIndex(
        flatNodes: [
          FileNode(
            type: NodeType.audio,
            title: 'local.mp3',
            hash: 'local-file',
            path: '/mixed/local.mp3',
            folderPath: '/mixed',
            rootPath: '/mixed',
            source: NodeSource.localWork,
          ),
          FileNode(
            type: NodeType.audio,
            title: 'remote.mp3',
            hash: 'remote-file',
            mediaStreamUrl: 'https://example.com/remote.mp3',
            path: '/mixed/remote.mp3',
            folderPath: '/mixed',
            rootPath: '/mixed',
            source: NodeSource.asmrServer,
          ),
        ],
        rootPath: '/mixed',
      );

      expect(index.isLocalContent, isFalse);
      expect(index.hasRemoteContent, isTrue);
    });
  });
}

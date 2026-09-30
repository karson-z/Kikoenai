import 'dart:io';

import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:path/path.dart' as p;

import 'local_scan_exclusions.dart';

class RenameProposal {
  const RenameProposal(this.node, this.newName);
  final FileNode node;
  final String newName;

  String get oldPath => node.path ?? node.mediaStreamUrl ?? '';
  String get newPath => p.join(p.dirname(oldPath), newName);
}

class RenameResult {
  const RenameResult(this.succeeded, this.failed);
  final List<RenameProposal> succeeded;
  final Map<RenameProposal, String> failed;
}

class LocalBatchRename {
  const LocalBatchRename();

  String baseName(FileNode node) =>
      node.isFolder ? node.title : p.basenameWithoutExtension(node.title);

  String extension(FileNode node) =>
      node.isFolder ? '' : p.extension(node.title);

  bool isPhysical(FileNode node) {
    final path = node.path ?? node.mediaStreamUrl;
    if (path == null || path.isEmpty) return false;
    return node.isFolder
        ? Directory(path).existsSync()
        : File(path).existsSync();
  }

  Map<RenameProposal, String> validate(List<RenameProposal> proposals) {
    final errors = <RenameProposal, String>{};
    final targets = <String, RenameProposal>{};
    final sources =
        proposals.map((proposal) => proposal.oldPath.toLowerCase()).toSet();
    for (final proposal in proposals) {
      final name = proposal.newName;
      if (name.isEmpty ||
          name == '.' ||
          name == '..' ||
          name.contains('/') ||
          name.contains('\\') ||
          name.contains('\u0000')) {
        errors[proposal] = '名称无效';
      } else if (!isPhysical(proposal.node)) {
        errors[proposal] = '源文件不存在或属于压缩包内部';
      } else if ((Directory(p.dirname(proposal.oldPath)).statSync().mode &
              0x92) ==
          0) {
        errors[proposal] = '目标目录不可写';
      } else if (!proposal.node.isFolder &&
          p.extension(name) != extension(proposal.node)) {
        errors[proposal] = '文件扩展名不可修改';
      } else if (proposal.newPath != proposal.oldPath) {
        final targetKey = proposal.newPath.toLowerCase();
        if (targets.containsKey(targetKey)) {
          errors[proposal] = '目标名称重复';
          errors[targets[targetKey]!] = '目标名称重复';
        } else if (sources.contains(targetKey) ||
            File(proposal.newPath).existsSync() ||
            Directory(proposal.newPath).existsSync()) {
          errors[proposal] = '目标路径已存在';
        }
        targets[targetKey] = proposal;
      }
    }
    return errors;
  }

  Future<RenameResult> execute(List<RenameProposal> proposals) async {
    if (validate(proposals).isNotEmpty) {
      throw StateError('请先修正重命名预览中的冲突');
    }
    final succeeded = <RenameProposal>[];
    final failed = <RenameProposal, String>{};
    for (final proposal in proposals) {
      if (proposal.newPath == proposal.oldPath) continue;
      try {
        if (proposal.node.isFolder) {
          await Directory(proposal.oldPath).rename(proposal.newPath);
        } else {
          await File(proposal.oldPath).rename(proposal.newPath);
        }
        succeeded.add(proposal);
        await const LocalScanExclusions().moveRulesUnderPath(
          proposal.oldPath,
          proposal.newPath,
        );
      } catch (error) {
        failed[proposal] = error.toString();
      }
    }
    return RenameResult(succeeded, failed);
  }
}

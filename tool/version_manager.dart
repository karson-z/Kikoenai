import 'dart:io';

void main(List<String> arguments) {
  try {
    final options = _Options.parse(arguments);
    final manager = _VersionManager(options.rootDirectory);

    switch (options.command) {
      case 'current':
        stdout.writeln(manager.current.full);
      case 'next':
        stdout.writeln(manager.current.bump(options.increment!).full);
      case 'bump':
        final next = manager.bump(options.increment!);
        stdout.writeln(next.full);
    }
  } on FormatException catch (error) {
    stderr.writeln('Version error: ${error.message}');
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Version file error: ${error.message}');
    exitCode = 74;
  }
}

enum _Increment { patch, minor, major }

class _Options {
  const _Options({
    required this.rootDirectory,
    required this.command,
    this.increment,
  });

  final Directory rootDirectory;
  final String command;
  final _Increment? increment;

  static _Options parse(List<String> arguments) {
    final args = [...arguments];
    var rootDirectory = File.fromUri(Platform.script).parent.parent;

    final rootIndex = args.indexOf('--root');
    if (rootIndex != -1) {
      if (rootIndex + 1 >= args.length) {
        throw const FormatException('--root requires a directory path.');
      }
      rootDirectory = Directory(args[rootIndex + 1]).absolute;
      args.removeRange(rootIndex, rootIndex + 2);
    }

    if (args.isEmpty) {
      return _Options(rootDirectory: rootDirectory, command: 'current');
    }

    final command = args.first;
    if (command == 'current' && args.length == 1) {
      return _Options(rootDirectory: rootDirectory, command: command);
    }

    if ((command == 'next' || command == 'bump') && args.length == 2) {
      final increment = _Increment.values.where(
        (value) => value.name == args[1],
      );
      if (increment.length == 1) {
        return _Options(
          rootDirectory: rootDirectory,
          command: command,
          increment: increment.single,
        );
      }
    }

    throw const FormatException(
      'Usage: version_manager.dart [current|next <patch|minor|major>|bump <patch|minor|major>]',
    );
  }
}

class _VersionManager {
  _VersionManager(Directory rootDirectory)
    : _pubspec = File('${rootDirectory.path}/kikoenai_app/pubspec.yaml'),
      _versionConfig = File(
        '${rootDirectory.path}/kikoenai_app/lib/config/app_version_config.dart',
      );

  static final RegExp _pubspecPattern = RegExp(
    r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
    multiLine: true,
  );
  static final RegExp _configPattern = RegExp(
    r'''static const String version\s*=\s*(['"])(\d+)\.(\d+)\.(\d+)\1;''',
  );

  final File _pubspec;
  final File _versionConfig;

  _Version get current {
    final pubspecText = _pubspec.readAsStringSync();
    final configText = _versionConfig.readAsStringSync();
    final pubspecMatch = _singleMatch(
      _pubspecPattern,
      pubspecText,
      'kikoenai_app/pubspec.yaml version',
    );
    final configMatch = _singleMatch(
      _configPattern,
      configText,
      'VersionConfig.version',
    );

    final pubspecVersion = _Version(
      int.parse(pubspecMatch.group(1)!),
      int.parse(pubspecMatch.group(2)!),
      int.parse(pubspecMatch.group(3)!),
      int.parse(pubspecMatch.group(4)!),
    );
    final configVersion = [
      configMatch.group(2),
      configMatch.group(3),
      configMatch.group(4),
    ].join('.');

    if (pubspecVersion.semantic != configVersion) {
      throw FormatException(
        'Version mismatch: pubspec has ${pubspecVersion.full}, '
        'but VersionConfig has $configVersion.',
      );
    }
    if (pubspecVersion.build != 1) {
      throw FormatException(
        'Flutter build number must remain 1, found ${pubspecVersion.build}.',
      );
    }
    return pubspecVersion;
  }

  _Version bump(_Increment increment) {
    final next = current.bump(increment);
    final pubspecText = _pubspec.readAsStringSync();
    final configText = _versionConfig.readAsStringSync();
    final pubspecMatch = _singleMatch(
      _pubspecPattern,
      pubspecText,
      'kikoenai_app/pubspec.yaml version',
    );
    final configMatch = _singleMatch(
      _configPattern,
      configText,
      'VersionConfig.version',
    );
    final quote = configMatch.group(1)!;

    final updatedPubspec = pubspecText.replaceRange(
      pubspecMatch.start,
      pubspecMatch.end,
      'version: ${next.full}',
    );
    final updatedConfig = configText.replaceRange(
      configMatch.start,
      configMatch.end,
      'static const String version = $quote${next.semantic}$quote;',
    );

    _pubspec.writeAsStringSync(updatedPubspec);
    _versionConfig.writeAsStringSync(updatedConfig);
    return next;
  }

  RegExpMatch _singleMatch(RegExp pattern, String input, String label) {
    final matches = pattern.allMatches(input).toList();
    if (matches.length != 1) {
      throw FormatException(
        'Expected exactly one $label declaration, found ${matches.length}.',
      );
    }
    return matches.single;
  }
}

class _Version {
  const _Version(this.major, this.minor, this.patch, this.build);

  final int major;
  final int minor;
  final int patch;
  final int build;

  String get semantic => '$major.$minor.$patch';
  String get full => '$semantic+$build';

  _Version bump(_Increment increment) {
    return switch (increment) {
      _Increment.patch => _Version(major, minor, patch + 1, 1),
      _Increment.minor => _Version(major, minor + 1, 0, 1),
      _Increment.major => _Version(major + 1, 0, 0, 1),
    };
  }
}

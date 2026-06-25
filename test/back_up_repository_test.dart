import 'dart:io';

import 'package:archive/archive.dart';
import 'package:ballistics_wallet_flutter/repository/back_up_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('backup-test-');
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('extracts a valid flat Hive backup', () async {
    final archive =
        Archive()
          ..addFile(ArchiveFile.string('bonusInfoBox.hive', 'valid backup'));
    final zipFile = await _writeArchive(archive, tempDirectory);
    final destination = Directory(p.join(tempDirectory.path, 'hive'));

    await extractBackupArchive(zipFile, destination);

    expect(
      await File(p.join(destination.path, 'bonusInfoBox.hive')).readAsString(),
      'valid backup',
    );
  });

  test(
    'rejects parent traversal without writing outside destination',
    () async {
      final archive =
          Archive()
            ..addFile(ArchiveFile.string('../escaped.hive', 'malicious'));
      final zipFile = await _writeArchive(archive, tempDirectory);
      final destination = Directory(p.join(tempDirectory.path, 'hive'));

      await expectLater(
        extractBackupArchive(zipFile, destination),
        throwsA(isA<FormatException>()),
      );

      expect(
        File(p.join(tempDirectory.path, 'escaped.hive')).existsSync(),
        false,
      );
    },
  );

  test('rejects nested and backslash archive paths', () async {
    for (final unsafeName in ['nested/file.hive', r'..\escaped.hive']) {
      final archive =
          Archive()..addFile(ArchiveFile.string(unsafeName, 'malicious'));
      final zipFile = await _writeArchive(archive, tempDirectory);

      await expectLater(
        extractBackupArchive(
          zipFile,
          Directory(p.join(tempDirectory.path, 'hive')),
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('rejects archives with too many entries before extraction', () async {
    final archive = Archive();
    for (var i = 0; i <= maxBackupEntries; i++) {
      archive.addFile(ArchiveFile.string('box-$i.hive', 'x'));
    }
    final zipFile = await _writeArchive(archive, tempDirectory);
    final destination = Directory(p.join(tempDirectory.path, 'hive'));

    await expectLater(
      extractBackupArchive(zipFile, destination),
      throwsA(isA<FormatException>()),
    );
    expect(destination.existsSync(), false);
  });

  test('rejects an oversized archive before reading it', () async {
    final zipFile = File(p.join(tempDirectory.path, 'oversized.zip'));
    await zipFile.open(mode: FileMode.write).then((file) async {
      await file.truncate(maxBackupArchiveBytes + 1);
      await file.close();
    });

    await expectLater(
      extractBackupArchive(
        zipFile,
        Directory(p.join(tempDirectory.path, 'hive')),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Future<File> _writeArchive(Archive archive, Directory tempDirectory) async {
  final file = File(
    p.join(
      tempDirectory.path,
      'archive-${DateTime.now().microsecondsSinceEpoch}.zip',
    ),
  );
  await file.writeAsBytes(ZipEncoder().encode(archive));
  return file;
}

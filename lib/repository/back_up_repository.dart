import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:ballistics_wallet_flutter/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const int maxBackupArchiveBytes = 20 * 1024 * 1024;
const int maxBackupEntryBytes = 20 * 1024 * 1024;
const int maxBackupExpandedBytes = 50 * 1024 * 1024;
const int maxBackupEntries = 128;

class BackupManager extends StateNotifier<BackupState> {
  BackupManager(this.authRepository) : super(BackupState());
  AuthRepository authRepository;

  /// Backups use application-private storage and require no broad storage
  /// permission. Kept for compatibility with existing UI call sites.
  Future<bool> requestPermissions() async => true;

  Future<void> backupData() async {
    state = BackupState(
      status: BackupStatus.processing,
      message: 'Processing Hive data...',
    );

    try {
      final docDir = await getApplicationDocumentsDirectory();
      // Assuming your Hive data is in the root of the documents directory or specify the correct path
      final hiveDataPath =
          '${docDir.path}/hive'; // Update this path if your Hive data is elsewhere

      final zipFilePath = '${docDir.path}/BallisticsWalletBackup.zip';
      await zipHiveFiles(hiveDataPath, zipFilePath); // Zip the Hive files

      await uploadFileToDrive(File(zipFilePath)); // Upload the ZIP file

      state = BackupState(
        status: BackupStatus.success,
        message: 'Hive data backup successful!',
      );
    } on Exception catch (e) {
      state = BackupState(status: BackupStatus.error, message: 'Error: $e');
    }
  }

  Future<void> zipHiveFiles(String sourceDirPath, String zipFilePath) async {
    final sourceDir = Directory(sourceDirPath);
    if (!sourceDir.existsSync()) {
      throw const FormatException('Local backup data was not found.');
    }

    final files =
        await sourceDir
            .list(followLinks: false)
            .where((entity) => entity is File)
            .cast<File>()
            .toList();
    if (files.length > maxBackupEntries) {
      throw const FormatException('Local backup contains too many files.');
    }

    var expandedBytes = 0;
    final encoder = ZipFileEncoder()..create(zipFilePath);
    try {
      for (final file in files) {
        final length = await file.length();
        if (length > maxBackupEntryBytes) {
          throw const FormatException('A local backup file is too large.');
        }
        expandedBytes += length;
        if (expandedBytes > maxBackupExpandedBytes) {
          throw const FormatException('Local backup data is too large.');
        }
        await encoder.addFile(file, p.basename(file.path));
      }
    } finally {
      await encoder.close();
    }
  }

  Future<void> uploadFileToDrive(File file) async {
    try {
      final googleUser = await authRepository.getCurrentGoogleUser();
      if (googleUser == null) {
        await authRepository.signInWithGoogle();
        return;
      }
      final googleAuth = googleUser.authentication;
      const scopes = ['https://www.googleapis.com/auth/drive.file'];
      final authz =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);

      final accessToken = AccessToken(
        'Bearer',
        authz.accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      final credentials = AccessCredentials(
        accessToken,
        googleAuth.idToken, // Typically not the refresh token
        scopes,
      );

      final authClient = authenticatedClient(http.Client(), credentials);
      try {
        final driveApi = drive.DriveApi(authClient);
        final fileList = await driveApi.files.list(
          q: "name = 'BallisticsWalletBackup.zip' and trashed = false",
          spaces: 'drive',
        );

        final fileToUpload = drive.File()..name = p.basename(file.path);
        final media = drive.Media(file.openRead(), await file.length());

        if (fileList.files != null && fileList.files!.isNotEmpty) {
          final existingFileId = fileList.files!.first.id!;
          await driveApi.files.update(
            fileToUpload,
            existingFileId,
            uploadMedia: media,
          );
        } else {
          await driveApi.files.create(fileToUpload, uploadMedia: media);
        }
      } finally {
        authClient.close();
      }
    } on FormatException catch (e) {
      if (e is drive.DetailedApiRequestError) {
        // Handle specific Drive API errors here
      }
    }
  }

  Future<File?> downloadBackupFile() async {
    try {
      final googleUser = await authRepository.getCurrentGoogleUser();
      if (googleUser == null) {
        await authRepository.signInWithGoogle();
        return null;
      }
      final googleAuth = googleUser.authentication;
      const scopes = ['https://www.googleapis.com/auth/drive.file'];
      final authz =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);

      final accessToken = AccessToken(
        'Bearer',
        authz.accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      final credentials = AccessCredentials(
        accessToken,
        googleAuth.idToken, // Placeholder, not used for refresh
        scopes,
      );

      final authClient = authenticatedClient(http.Client(), credentials);
      try {
        final driveApi = drive.DriveApi(authClient);
        final fileList = await driveApi.files.list(
          q: "name = 'BallisticsWalletBackup.zip' and trashed = false",
          spaces: 'drive',
        );

        if (fileList.files == null || fileList.files!.isEmpty) {
          return null;
        }

        final file = fileList.files!.first;
        final media =
            await driveApi.files.get(
                  file.id!,
                  downloadOptions: drive.DownloadOptions.fullMedia,
                )
                as drive.Media;

        final docDir = await getApplicationDocumentsDirectory();
        final localFile = File('${docDir.path}/BallisticsWalletBackup.zip');
        final sink = localFile.openWrite();
        var downloadedBytes = 0;
        try {
          await for (final chunk in media.stream) {
            downloadedBytes += chunk.length;
            if (downloadedBytes > maxBackupArchiveBytes) {
              throw const FormatException('Backup archive is too large.');
            }
            sink.add(chunk);
          }
        } catch (_) {
          await sink.close();
          if (localFile.existsSync()) {
            localFile.deleteSync();
          }
          rethrow;
        }
        await sink.close();
        return localFile;
      } finally {
        authClient.close();
      }
    } on FormatException {
      return null;
    }
  }

  Future<void> extractAndOverwriteHiveData(File zipFile) async {
    final docDir = await getApplicationDocumentsDirectory();
    await extractBackupArchive(zipFile, Directory(p.join(docDir.path, 'hive')));
  }

  Future<void> restoreBackup() async {
    state = BackupState(
      status: BackupStatus.processing,
      message: 'Restoring backup...',
    );

    final backupFile = await downloadBackupFile();
    if (backupFile != null) {
      await extractAndOverwriteHiveData(backupFile);

      state = BackupState(
        status: BackupStatus.success,
        message: 'Backup restored successfully!',
      );
    } else {
      state = BackupState(
        status: BackupStatus.error,
        message: 'Backup file not found.',
      );
    }
  }

  Future<void> checkActiveState() async {
    final googleUser = await authRepository.getCurrentGoogleUser();
    state = state.copyWith(isActive: googleUser != null);
  }
}

/// Extracts the app's flat Hive backup format after validating every entry.
Future<void> extractBackupArchive(File zipFile, Directory destination) async {
  final compressedBytes = await zipFile.length();
  if (compressedBytes <= 0 || compressedBytes > maxBackupArchiveBytes) {
    throw const FormatException('Backup archive has an invalid size.');
  }

  final archive = ZipDecoder().decodeBytes(
    await zipFile.readAsBytes(),
    verify: true,
  );
  if (archive.length > maxBackupEntries) {
    throw const FormatException('Backup archive contains too many files.');
  }

  var expandedBytes = 0;
  final validatedFiles = <(ArchiveFile, String)>[];
  for (final entry in archive) {
    if (!entry.isFile || entry.isSymbolicLink) {
      throw const FormatException('Backup archive contains an invalid entry.');
    }

    final normalizedName = entry.name.replaceAll(r'\', '/');
    final safeName = p.posix.basename(normalizedName);
    if (safeName.isEmpty ||
        safeName == '.' ||
        safeName == '..' ||
        safeName != normalizedName ||
        p.posix.isAbsolute(normalizedName) ||
        RegExp('^[a-zA-Z]:').hasMatch(normalizedName)) {
      throw const FormatException('Backup archive contains an unsafe path.');
    }

    if (entry.size < 0 || entry.size > maxBackupEntryBytes) {
      throw const FormatException('Backup archive contains an oversized file.');
    }
    expandedBytes += entry.size;
    if (expandedBytes > maxBackupExpandedBytes) {
      throw const FormatException('Expanded backup data is too large.');
    }
    validatedFiles.add((entry, safeName));
  }

  await destination.create(recursive: true);
  for (final (entry, safeName) in validatedFiles) {
    final content = entry.content;
    if (content.length != entry.size) {
      throw const FormatException('Backup archive contains invalid data.');
    }
    await File(
      p.join(destination.path, safeName),
    ).writeAsBytes(content, flush: true);
  }
}

enum BackupStatus { initial, processing, success, error }

class BackupState {
  BackupState({
    this.status = BackupStatus.initial,
    this.message = '',
    this.isActive = false,
  });

  final BackupStatus status;
  final String message;
  final bool isActive;

  BackupState copyWith({
    BackupStatus? status,
    String? message,
    bool? isActive,
  }) => BackupState(
    status: status ?? this.status,
    message: message ?? this.message,
    isActive: isActive ?? this.isActive,
  );
}

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:ballistics_wallet_flutter/repository/auth_repository.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers, this._inner);
  final Map<String, String> _headers;
  final http.Client _inner;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class BackupManager extends StateNotifier<BackupState> {
  BackupManager(this.authRepository) : super(BackupState());
  AuthRepository authRepository;
  final httpClient = http.Client();

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    // No runtime storage permission is needed (or even available) for app-internal dirs.
    if (sdk >= 29) return true;

    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    final result = await Permission.storage.request();
    return result.isGranted;
  }

  Future<void> backupData() async {
    state = BackupState(
      status: BackupStatus.processing,
      message: 'Processing Hive data...',
    );

    try {
      await requestPermissions();
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
      return;
    }
    final files = sourceDir.listSync().whereType<File>().toList();

    final archive = Archive();
    for (final file in files) {
      final archiveFile = ArchiveFile(
        p.basename(file.path),
        file.lengthSync(),
        await file.readAsBytes(),
      );
      archive.addFile(archiveFile);
    }

    File(zipFilePath)
        .writeAsBytesSync(ZipEncoder().encode(archive), flush: true);
  }

  Future<void> uploadFileToDrive(File file) async {
    try {
      final account = authRepository.currentUserId;
      if (account.isEmpty) {
        throw BackupAuthException('notSignedIn', 'No Google account available.');
      }

      // Use Google-provided auth headers (Bearer access token). If Drive scope
      // was not previously granted, Drive will respond with 403 which we map
      // to a scope error for the UI to handle.
      final token = account;
      if (token.isEmpty) {
        // The account is signed in, but does not have an access token for Drive (scope not granted)
        throw BackupAuthException('missingDriveScope', 'Drive permission not granted.');
      }
      final headers = {'Authorization': 'Bearer $token'};
      final client = _GoogleAuthClient(headers, http.Client());
      final driveApi = drive.DriveApi(client);

      final fileList = await driveApi.files.list(
        q: "name = 'BallisticsWalletBackup.zip' and trashed = false",
        spaces: 'drive',
      );

      final fileMeta = drive.File()..name = p.basename(file.path);
      final media = drive.Media(file.openRead(), file.lengthSync());

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files.update(fileMeta, existingFileId, uploadMedia: media);
      } else {
        await driveApi.files.create(fileMeta, uploadMedia: media);
      }

      client.close();
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 401 || e.status == 403) {
        throw BackupAuthException('missingDriveScope', 'Drive permission not granted.');
      }
      throw BackupException('Drive API error: ${e.status} ${e.message}');
    } on Exception catch (e) {
      throw BackupException('Upload failed: $e');
    }
  }

  Future<void> prompt(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {}
  }

  Future<File?> downloadBackupFile() async {
    try {
      await requestPermissions(); // this is non‑interactive on modern Android

      // Get account without UI; if none, tell the UI to handle sign‑in
      final account = await authRepository.currentGoogleAccountNonInteractive();
      if (account == null) {
        throw BackupAuthException('notSignedIn', 'No Google account available.');
      }
      const driveScopes = ['https://www.googleapis.com/auth/drive.file'];

      // Non‑interactive: just fetch headers. If scope isn’t granted yet,
      // Drive will reply 401/403 and we map that to missingDriveScope.
      Map<String, String>? headers;
      try {
        // Non-interactive: returns headers if scope is already granted, else throws.
        headers = await account.authorizationClient.authorizationHeaders(driveScopes);
      } on FormatException catch (_) {
        // No consent yet -> let UI handle consent and retry once.
        throw BackupAuthException('missingDriveScope', 'Drive permission not granted.');
      }

      final client = _GoogleAuthClient(headers!, http.Client());
      final driveApi = drive.DriveApi(client);

      // List files in Google Drive
      final fileList = await driveApi.files.list(
        q: "name = 'BallisticsWalletBackup.zip'",
        spaces: 'drive',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        client.close();
        return null;
      }

      final file = fileList.files!.first;

      // Download the file
      final media = await driveApi.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Save the file locally
      final docDir = await getApplicationDocumentsDirectory();
      final localFile = File('${docDir.path}/BallisticsWalletBackup.zip');
      final dataStore = <int>[];
      await media.stream.forEach(dataStore.addAll);
      await localFile.writeAsBytes(dataStore);

      client.close();
      return localFile;
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 401 || e.status == 403) {
        throw BackupAuthException('missingDriveScope', 'Drive permission not granted.');
      }
      throw BackupException('Drive API error: ${e.status} ${e.message}');
    } catch (e) {
      throw BackupException('Download failed: $e');
    }
  }

  Future<void> extractAndOverwriteHiveData(File zipFile) async {
    final docDir = await getApplicationDocumentsDirectory();
    final hiveDataPath =
        '${docDir.path}/hive'; // Path where Hive data is stored

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      final filePath = p.join(hiveDataPath, filename);

      if (file.isFile) {
        final fileData = file.content as List<int>;
        File(filePath)
          ..createSync(recursive: true) // Ensure the path exists
          ..writeAsBytesSync(
            fileData,
            flush: true,
          ); // Overwrite any existing file
      } else {
        if (!Directory(filePath).existsSync()) {
          Directory(filePath).createSync(recursive: true);
        }
      }
    }
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
    final account = authRepository.currentUserId;
    final isActive = account.isNotEmpty; // silent probe only; no scope prompt here
    state = state.copyWith(isActive: isActive);
  }
}

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
}

class BackupAuthException extends BackupException { // e.g., 'notSignedIn', 'missingDriveScope'
  BackupAuthException(this.code, String message) : super(message);
  final String code;
  @override
  String toString() => '$code: $message';
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
  }) {
    return BackupState(
      status: status ?? this.status,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
    );
  }
}

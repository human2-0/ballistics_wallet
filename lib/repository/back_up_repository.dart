import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:ballistics_wallet_flutter/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class BackupManager extends StateNotifier<BackupState> {
  BackupManager(this.authRepository) : super(BackupState());
  AuthRepository authRepository;
  final httpClient = http.Client();

  Future<bool> requestPermissions() async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final result = await Permission.storage.request();

    if (result.isGranted) {
      return true;
    } else {
      if (result.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }
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
        .writeAsBytesSync(ZipEncoder().encode(archive)!, flush: true);
  }

  Future<void> uploadFileToDrive(File file) async {
    try {
      final googleUser = await authRepository.getCurrentGoogleUser();
      if (googleUser == null) {
        await authRepository.signInWithGoogle();
        return;
      }
      final googleAuth = await googleUser.authentication;
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
      final driveApi = drive.DriveApi(authClient);

      // Search for the existing file
      final fileList = await driveApi.files.list(
        q: "name = 'BallisticsWalletBackup.zip' and trashed = false",
        spaces: 'drive',
      );

      final fileToUpload = drive.File()..name = p.basename(file.path);
      final media = drive.Media(file.openRead(), file.lengthSync());

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // File exists, update it
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files
            .update(fileToUpload, existingFileId, uploadMedia: media);
      } else {
        // File does not exist, create it
      }

      authClient.close();
    } on FormatException catch (e) {
      if (e is drive.DetailedApiRequestError) {
        // Handle specific Drive API errors here
      }
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
      await requestPermissions();
      final googleUser = await authRepository.getCurrentGoogleUser();
      if (googleUser == null) {
        await authRepository.signInWithGoogle();
        return null;
      }
      final googleAuth = await googleUser.authentication;
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
      final driveApi = drive.DriveApi(authClient);

      // List files in Google Drive
      final fileList = await driveApi.files.list(
        q: "name = 'BallisticsWalletBackup.zip'",
        spaces: 'drive',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
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
      return localFile;
    } on FormatException catch (e) {
      return null;
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
    final hasPermission = await Permission.storage.isGranted;
    final googleUser = await authRepository.getCurrentGoogleUser();
    final isActive = hasPermission && googleUser != null;

    state = state.copyWith(isActive: isActive);
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
  }) {
    return BackupState(
      status: status ?? this.status,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
    );
  }
}

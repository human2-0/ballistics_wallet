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
    print('Requesting storage permissions...');
    final status = await Permission.storage.status;

    if (status.isGranted) {
      print('Storage permission already granted.');
      return true;
    }

    if (status.isPermanentlyDenied) {
      print(
        'Storage permission is permanently denied. Opening app settings...',
      );
      await openAppSettings();
      return false;
    }

    print('Storage permission not granted, requesting...');
    final result = await Permission.storage.request();
    print('Permission request result: $result');

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
    print('Starting Hive data backup process...');

    try {
      await requestPermissions();
      final docDir = await getApplicationDocumentsDirectory();
      // Assuming your Hive data is in the root of the documents directory or specify the correct path
      final hiveDataPath =
          '${docDir.path}/hive'; // Update this path if your Hive data is elsewhere

      final zipFilePath = '${docDir.path}/BallisticsWalletBackup.zip';
      print('Zipping Hive files at path: $hiveDataPath');
      await zipHiveFiles(hiveDataPath, zipFilePath); // Zip the Hive files

      print('Uploading Hive backup to Google Drive...');
      await uploadFileToDrive(File(zipFilePath)); // Upload the ZIP file

      state = BackupState(
        status: BackupStatus.success,
        message: 'Hive data backup successful!',
      );
      print('Hive data backup successful!');
    } on Exception catch (e) {
      state = BackupState(status: BackupStatus.error, message: 'Error: $e');
      print('Error during Hive data backup process: $e');
    }
  }

  Future<void> zipHiveFiles(String sourceDirPath, String zipFilePath) async {
    final sourceDir = Directory(sourceDirPath);
    if (!sourceDir.existsSync()) {
      print('Hive directory does not exist: $sourceDirPath');
      return;
    }
    final files = sourceDir.listSync().whereType<File>().toList();

    final archive = Archive();
    for (final file in files) {
      print('Adding file to archive: ${file.path}');
      final archiveFile = ArchiveFile(
        p.basename(file.path),
        file.lengthSync(),
        await file.readAsBytes(),
      );
      archive.addFile(archiveFile);
    }

    final zipFile = File(zipFilePath);
    print('Writing zip file to disk: $zipFilePath');
    zipFile.writeAsBytesSync(ZipEncoder().encode(archive)!, flush: true);
  }

  Future<void> uploadFileToDrive(File file) async {
    try {
      final googleUser = await authRepository.getCurrentGoogleUser();
      if (googleUser == null) {
        print('User not signed in');
        await authRepository.signInWithGoogle();
        return;
      }
      final googleAuth = await googleUser.authentication;

      final accessToken = AccessToken(
        'Bearer',
        googleAuth.accessToken!,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      final credentials = AccessCredentials(
        accessToken,
        googleAuth.idToken, // Typically not the refresh token
        ['https://www.googleapis.com/auth/drive.file'],
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
        print('Updated existing file with ID: $existingFileId');
      } else {
        // File does not exist, create it
        final response =
            await driveApi.files.create(fileToUpload, uploadMedia: media);
        print('Uploaded new file with ID: ${response.id}');
      }

      authClient.close();
    } on FormatException catch (e) {
      print('Failed to upload file: $e');
      if (e is drive.DetailedApiRequestError) {
        // Handle specific Drive API errors here
        print('Drive API Error: ${e.message}');
      }
    }
  }

  Future<void> prompt(String url) async {
    final uri = Uri.parse(url);
    print('Prompting user to authenticate: $url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      print('URL successfully launched: $url');
    } else {
      print('Could not launch URL: $url');
    }
  }

  Future<File?> downloadBackupFile() async {
    try {
      await requestPermissions();
      final googleUser = await authRepository.getCurrentGoogleUser();
      if (googleUser == null) {
        print('User not signed in');
        await authRepository.signInWithGoogle();
        return null;
      }
      final googleAuth = await googleUser.authentication;

      final accessToken = AccessToken(
        'Bearer',
        googleAuth.accessToken!,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      final credentials = AccessCredentials(
        accessToken,
        googleAuth.idToken, // Placeholder, not used for refresh
        ['https://www.googleapis.com/auth/drive.file'],
      );

      final authClient = authenticatedClient(http.Client(), credentials);
      final driveApi = drive.DriveApi(authClient);

      // List files in Google Drive
      final fileList = await driveApi.files.list(
        q: "name = 'BallisticsWalletBackup.zip'",
        spaces: 'drive',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        print('No backup file found on Google Drive');
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
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }
      await localFile.writeAsBytes(dataStore);
      print('Backup file downloaded: ${localFile.path}');
      return localFile;
    } on FormatException catch (e) {
      print('Failed to download file: $e');
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
        print('Extracted and overwritten file: $filename');
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
    print('Starting backup restoration process...');

    final backupFile = await downloadBackupFile();
    if (backupFile != null) {
      print('Backup file downloaded, starting extraction...');
      await extractAndOverwriteHiveData(backupFile);

      state = BackupState(
        status: BackupStatus.success,
        message: 'Backup restored successfully!',
      );
      print('Backup restored successfully!');
    } else {
      state = BackupState(
        status: BackupStatus.error,
        message: 'Backup file not found.',
      );
      print('Backup file not found.');
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

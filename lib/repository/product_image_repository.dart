import 'dart:io';
import 'dart:typed_data';

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/repository/auth_repository.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/painting.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Handles runtime product image downloads and Drive intake uploads.
class ProductImageRepository {
  /// Creates a product image repository.
  ProductImageRepository(this.authRepository, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const _driveFolderName = 'lush_assets';
  static const _maxImageBytes = 5 * 1024 * 1024;
  static const _downloadTimeout = Duration(seconds: 20);
  static const _driveScopes = ['https://www.googleapis.com/auth/drive.file'];

  /// Authentication repository used for Drive upload authorization.
  final AuthRepository authRepository;
  final http.Client _httpClient;

  /// Releases the reusable download client.
  void dispose() => _httpClient.close();

  /// Returns a locally downloaded product image, if one exists.
  static Future<File?> localImageFile(String imageName) async {
    final name = imageName.trim();
    if (name.isEmpty || name == 'question') return null;

    final directory = await _productImagesDirectory();
    final file = File(p.join(directory.path, '$name.png'));
    return file.existsSync() ? file : null;
  }

  /// Downloads an image URL, saves it locally, and tries to upload it to Drive.
  Future<ProductImageSaveResult> saveProductImageFromUrl({
    required ProductInfo product,
    required String imageUrl,
  }) async {
    final uri = Uri.tryParse(imageUrl.trim());
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      throw const FormatException('Paste a valid http or https image link.');
    }

    final request = http.Request('GET', uri);
    final response = await _httpClient.send(request).timeout(_downloadTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
        'Image download failed: HTTP ${response.statusCode}.',
      );
    }

    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > _maxImageBytes) {
      throw const FormatException('Image must be between 1 byte and 5 MB.');
    }

    final buffer = BytesBuilder(copy: false);
    var receivedBytes = 0;
    await for (final chunk in response.stream.timeout(_downloadTimeout)) {
      receivedBytes += chunk.length;
      if (receivedBytes > _maxImageBytes) {
        throw const FormatException('Image must be between 1 byte and 5 MB.');
      }
      buffer.add(chunk);
    }

    final contentType = response.headers['content-type'] ?? '';
    final bytes = buffer.takeBytes();
    if (bytes.isEmpty || bytes.length > _maxImageBytes) {
      throw const FormatException('Image must be between 1 byte and 5 MB.');
    }
    if (!_looksLikeImage(contentType, bytes)) {
      throw const FormatException('The link did not return a supported image.');
    }

    return _saveProductImageBytes(product: product, bytes: bytes);
  }

  /// Saves image bytes locally and tries to upload them to Drive.
  Future<ProductImageSaveResult> saveProductImageFromBytes({
    required ProductInfo product,
    required Uint8List bytes,
  }) {
    if (bytes.isEmpty || bytes.length > _maxImageBytes) {
      throw const FormatException('Image must be between 1 byte and 5 MB.');
    }
    if (!_looksLikeImage('', bytes)) {
      throw const FormatException('Choose a supported image file.');
    }

    return _saveProductImageBytes(product: product, bytes: bytes);
  }

  /// Uploads a product image to the `lush_assets` Google Drive folder.
  Future<void> uploadProductImageToDrive(File file) async {
    final connection = await _driveConnection();
    try {
      final driveApi = connection.api;
      final folderId = await _findOrCreateDriveFolder(driveApi);
      final fileName = p.basename(file.path);
      final media = drive.Media(file.openRead(), await file.length());
      final metadata =
          drive.File()
            ..name = fileName
            ..parents = [folderId];

      final existing = await _findExistingDriveFile(
        driveApi: driveApi,
        fileName: fileName,
        folderId: folderId,
      );

      if (existing != null) {
        final existingParents = existing.parents ?? const <String>[];
        final parentsToRemove = existingParents
            .where((parentId) => parentId != folderId)
            .join(',');
        await driveApi.files.update(
          metadata,
          existing.id!,
          addParents: existingParents.contains(folderId) ? null : folderId,
          removeParents: parentsToRemove.isEmpty ? null : parentsToRemove,
          uploadMedia: media,
        );
      } else {
        await driveApi.files.create(metadata, uploadMedia: media);
      }
    } finally {
      connection.client.close();
    }
  }

  static Future<Directory> _productImagesDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(docDir.path, 'product_images'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<ProductImageSaveResult> _saveProductImageBytes({
    required ProductInfo product,
    required List<int> bytes,
  }) async {
    final imageName = productNameToImageName(product.productName);
    final directory = await _productImagesDirectory();
    final file = File(p.join(directory.path, '$imageName.png'));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    await FileImage(file).evict();

    var uploadedToDrive = false;
    try {
      await uploadProductImageToDrive(file);
      uploadedToDrive = true;
    } on Object {
      uploadedToDrive = false;
    }

    return ProductImageSaveResult(
      imageName: imageName,
      file: file,
      uploadedToDrive: uploadedToDrive,
    );
  }

  Future<_DriveConnection> _driveConnection() async {
    var googleUser = await authRepository.getCurrentGoogleUser();
    if (googleUser == null) {
      await authRepository.signInWithGoogle();
      googleUser = await authRepository.getCurrentGoogleUser();
    }
    if (googleUser == null) {
      throw const FormatException('notSignedIn');
    }

    final googleAuth = googleUser.authentication;
    final authz =
        await googleUser.authorizationClient.authorizationForScopes(
          _driveScopes,
        ) ??
        await googleUser.authorizationClient.authorizeScopes(_driveScopes);

    final accessToken = AccessToken(
      'Bearer',
      authz.accessToken,
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    final credentials = AccessCredentials(
      accessToken,
      googleAuth.idToken,
      _driveScopes,
    );

    final client = authenticatedClient(http.Client(), credentials);
    return _DriveConnection(drive.DriveApi(client), client);
  }

  Future<String> _findOrCreateDriveFolder(drive.DriveApi driveApi) async {
    final folders = await driveApi.files.list(
      q:
          "name = '$_driveFolderName' and "
          "mimeType = 'application/vnd.google-apps.folder' and "
          "'root' in parents and trashed = false",
      spaces: 'drive',
      $fields: 'files(id)',
    );

    if (folders.files != null && folders.files!.isNotEmpty) {
      return folders.files!.first.id!;
    }

    final folder =
        drive.File()
          ..name = _driveFolderName
          ..mimeType = 'application/vnd.google-apps.folder'
          ..parents = ['root'];
    final created = await driveApi.files.create(folder, $fields: 'id');
    return created.id!;
  }

  Future<drive.File?> _findExistingDriveFile({
    required drive.DriveApi driveApi,
    required String fileName,
    required String folderId,
  }) async {
    final escapedFileName = _escapeDriveQuery(fileName);
    final folderFiles = await driveApi.files.list(
      q:
          "name = '$escapedFileName' and "
          "'$folderId' in parents and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, parents)',
    );

    final filesInFolder = folderFiles.files;
    if (filesInFolder != null && filesInFolder.isNotEmpty) {
      return filesInFolder.first;
    }

    final matchingFiles = await driveApi.files.list(
      q: "name = '$escapedFileName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, parents)',
    );

    final files = matchingFiles.files;
    if (files == null || files.isEmpty) {
      return null;
    }
    return files.first;
  }

  static String _escapeDriveQuery(String value) => value.replaceAll("'", r"\'");

  static bool _looksLikeImage(String contentType, List<int> bytes) {
    if (contentType.startsWith('image/')) return true;
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return true;
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return true;
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return true;
    }
    return false;
  }
}

class _DriveConnection {
  const _DriveConnection(this.api, this.client);

  final drive.DriveApi api;
  final http.Client client;
}

/// Result of saving a product image from a pasted URL.
class ProductImageSaveResult {
  /// Creates a product image save result.
  const ProductImageSaveResult({
    required this.imageName,
    required this.file,
    required this.uploadedToDrive,
  });

  /// Product image key saved to Firestore.
  final String imageName;

  /// Local file saved in the app documents image cache.
  final File file;

  /// Whether the optional Google Drive upload succeeded.
  final bool uploadedToDrive;
}

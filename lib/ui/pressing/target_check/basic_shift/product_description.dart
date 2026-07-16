import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/custom_widgets/product_image_view.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_image_provider.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart'
    show dismissTargetCheckInputs, lastSelectedProductProvider;
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/product_image_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';

/// Sort order for the product history list.
enum HistorySort {
  /// Show the newest product history entries first.
  newest,

  /// Show the oldest product history entries first.
  oldest,

  /// Show the highest bonus product history entries first.
  highestBonus,
}

/// Opens the product note bottom sheet for the currently focused product.
Future<void> showProductNoteDialog(BuildContext context, WidgetRef ref) async {
  dismissTargetCheckInputs(ref);
  final product = ref.read(focusedProductProvider);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    requestFocus: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ProductNoteSheet(product: product),
  );
}

class _ProductNoteSheet extends ConsumerStatefulWidget {
  const _ProductNoteSheet({required this.product});

  final ProductInfo product;

  @override
  ConsumerState<_ProductNoteSheet> createState() => _ProductNoteSheetState();
}

class _ProductNoteSheetState extends ConsumerState<_ProductNoteSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final String _originalDescription;
  late ProductInfo _product;
  late bool _isEditing;
  bool _isSavingImage = false;
  HistorySort _sort = HistorySort.newest;
  bool _didRequestFocus = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _originalDescription = _product.description ?? '';
    _controller = TextEditingController(text: _originalDescription);
    _focusNode = FocusNode();
    // Product details open in viewing mode. Editing (and keyboard focus) only
    // starts after the user explicitly taps Edit.
    _isEditing = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _showAddImageDialog() async {
    // The description field can otherwise reclaim focus when the nested image
    // dialog closes, immediately reopening the keyboard over this sheet.
    _focusNode
      ..unfocus()
      ..canRequestFocus = false;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final result = await showDialog<_AddProductImageResult>(
        context: context,
        builder: (_) => _AddProductImageDialog(product: _product),
      );

      if (!mounted || result == null) return;
      FocusManager.instance.primaryFocus?.unfocus();
      switch (result.method) {
        case _AddImageMethod.url:
          final imageUrl = result.imageUrl;
          if (imageUrl == null || imageUrl.isEmpty) return;
          await _saveImageFromUrl(imageUrl, result);
        case _AddImageMethod.clipboard:
          final bytes = result.imageBytes;
          if (bytes == null || bytes.isEmpty) return;
          await _saveImageFromBytes(bytes, result);
        case _AddImageMethod.library:
          final bytes = result.imageBytes;
          if (bytes == null || bytes.isEmpty) return;
          await _saveImageFromBytes(bytes, result);
        case _AddImageMethod.current:
          await _saveImagePresentation(result);
      }
    } finally {
      if (mounted) {
        _focusNode.canRequestFocus = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) FocusManager.instance.primaryFocus?.unfocus();
        });
      }
    }
  }

  Future<void> _saveImageFromUrl(
    String imageUrl,
    _AddProductImageResult presentation,
  ) async {
    await _saveImage(
      (repository) => repository.saveProductImageFromUrl(
        product: _product,
        imageUrl: imageUrl,
      ),
      presentation,
    );
  }

  Future<void> _saveImageFromBytes(
    Uint8List bytes,
    _AddProductImageResult presentation,
  ) async {
    await _saveImage(
      (repository) =>
          repository.saveProductImageFromBytes(product: _product, bytes: bytes),
      presentation,
    );
  }

  Future<void> _saveImage(
    Future<ProductImageSaveResult> Function(ProductImageRepository repository)
    save,
    _AddProductImageResult presentation, {
    bool manageSavingState = true,
  }) async {
    if (manageSavingState) {
      setState(() => _isSavingImage = true);
    }
    try {
      final result = await save(ref.read(productImageRepositoryProvider));
      final updated = _product.copyWith(
        imageName: result.imageName,
        imageScale: presentation.imageScale,
        imageOffsetX: presentation.imageOffsetX,
        imageOffsetY: presentation.imageOffsetY,
      );
      final saved = await ref
          .read(productInfoProvider.notifier)
          .editProductInfo(updated);
      if (!saved) {
        throw const FormatException('Product image name was not saved.');
      }

      await ref
          .read(lastSelectedProductProvider.notifier)
          .saveSelectedProduct(updated);
      ref.read(focusedProductProvider.notifier).state = updated;
      if (!mounted) return;
      setState(() => _product = updated);

      showAppNotification(
        context,
        result.uploadedToDrive
            ? 'Image saved and uploaded to Google Drive.'
            : 'Image saved locally. Google Drive upload failed.',
        type:
            result.uploadedToDrive
                ? AppNotificationType.success
                : AppNotificationType.warning,
      );
    } on Object catch (error) {
      if (!mounted) return;
      showAppNotification(
        context,
        'Failed to add image: $error',
        type: AppNotificationType.error,
      );
    } finally {
      if (mounted && manageSavingState) {
        setState(() => _isSavingImage = false);
      }
    }
  }

  Future<void> _saveImagePresentation(
    _AddProductImageResult presentation,
  ) async {
    setState(() => _isSavingImage = true);
    try {
      final updated = _product.copyWith(
        imageScale: presentation.imageScale,
        imageOffsetX: presentation.imageOffsetX,
        imageOffsetY: presentation.imageOffsetY,
      );
      final saved = await ref
          .read(productInfoProvider.notifier)
          .editProductInfo(updated);
      if (!saved) {
        throw const FormatException('Product image view was not saved.');
      }
      await ref
          .read(lastSelectedProductProvider.notifier)
          .saveSelectedProduct(updated);
      ref.read(focusedProductProvider.notifier).state = updated;
      if (!mounted) return;
      setState(() => _product = updated);
      showAppNotification(
        context,
        'Image view updated.',
        type: AppNotificationType.success,
      );
    } on Object catch (error) {
      if (!mounted) return;
      showAppNotification(
        context,
        'Failed to update image view: $error',
        type: AppNotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isSavingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref
        .read(bonusInfoListProvider.notifier)
        .getProductHistory(_product.productName);
    final sortedHistory = [...history];
    switch (_sort) {
      case HistorySort.highestBonus:
        sortedHistory.sort((a, b) => b.bonus.compareTo(a.bonus));
      case HistorySort.newest:
        sortedHistory.sort((a, b) => b.date.compareTo(a.date));
      case HistorySort.oldest:
        sortedHistory.sort((a, b) => a.date.compareTo(b.date));
    }

    if (_isEditing && !_didRequestFocus) {
      _didRequestFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        // keep the sheet above the keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _product.productName.isEmpty
                    ? 'Product note'
                    : '${_product.productName} note',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _ImageToolsRow(
                imageName: _product.imageName,
                isSaving: _isSavingImage,
                onAddImage: _showAddImageDialog,
              ),
              const SizedBox(height: 16),
              TextFieldTapRegion(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 80,
                    maxHeight: 160,
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    readOnly: !_isEditing,
                    maxLength: 400,
                    focusNode: _focusNode,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText:
                          _isEditing
                              ? 'Add tips, tricks, sweet-spot powder amounts, '
                                  'or anything else helpful...'
                              : null,
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.35),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.75),
                          width: 1.4,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '${_controller.text.length}/400',
                      counterStyle: Theme.of(context).textTheme.labelSmall,
                      suffixIcon:
                          _isEditing
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Clear',
                                    icon: const Icon(Icons.close),
                                    onPressed: _controller.clear,
                                  ),
                                ],
                              )
                              : null,
                    ),
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextFieldTapRegion(
                  child: _DescriptionToolbar(
                    onInsert: (s) {
                      final sel = _controller.selection;
                      if (!sel.isValid) {
                        _controller
                          ..text = '${_controller.text}$s'
                          ..selection = TextSelection.collapsed(
                            offset: _controller.text.length,
                          );
                      } else {
                        final newText = _controller.text.replaceRange(
                          sel.start,
                          sel.end,
                          s,
                        );
                        final newOffset = sel.start + s.length;
                        _controller.value = _controller.value.copyWith(
                          text: newText,
                          selection: TextSelection.collapsed(offset: newOffset),
                          composing: TextRange.empty,
                        );
                      }
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'History',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    _sort == HistorySort.highestBonus
                        ? 'Highest bonus'
                        : (_sort == HistorySort.oldest ? 'Oldest' : 'Newest'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<HistorySort>(
                    tooltip: 'Sort history',
                    icon: const Icon(Icons.sort),
                    onSelected: (value) => setState(() => _sort = value),
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem(
                            value: HistorySort.newest,
                            child: Text('Newest'),
                          ),
                          PopupMenuItem(
                            value: HistorySort.oldest,
                            child: Text('Oldest'),
                          ),
                          PopupMenuItem(
                            value: HistorySort.highestBonus,
                            child: Text('Highest bonus'),
                          ),
                        ],
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child:
                    sortedHistory.isEmpty
                        ? const Center(child: Text('No history available.'))
                        : ListView.separated(
                          itemCount: sortedHistory.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final entry = sortedHistory[index];
                            return _HistoryTile(
                              date: entry.date,
                              bonus: entry.bonus,
                            );
                          },
                        ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isEditing)
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          _didRequestFocus = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  if (_isEditing)
                    OutlinedButton(
                      onPressed: () {
                        _controller.text = _originalDescription;
                        dismissTargetCheckInputs(ref);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  if (!_isEditing)
                    OutlinedButton(
                      onPressed: () {
                        dismissTargetCheckInputs(ref);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  if (_isEditing)
                    ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final updated = _product.copyWith(
                          description: _controller.text,
                        );
                        await ref
                            .read(productInfoProvider.notifier)
                            .editProductInfo(updated);
                        await ref
                            .read(lastSelectedProductProvider.notifier)
                            .saveSelectedProduct(updated);
                        ref.read(focusedProductProvider.notifier).state =
                            updated;
                        if (mounted) Navigator.pop(this.context);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProductImageDialog extends StatefulWidget {
  const _AddProductImageDialog({required this.product});

  final ProductInfo product;

  @override
  State<_AddProductImageDialog> createState() => _AddProductImageDialogState();
}

enum _AddImageMethod { url, clipboard, library, current }

class _AddProductImageResult {
  const _AddProductImageResult(
    this.method, {
    required this.imageScale,
    required this.imageOffsetX,
    required this.imageOffsetY,
    this.imageUrl,
    this.imageBytes,
  });

  final _AddImageMethod method;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double imageScale;
  final double imageOffsetX;
  final double imageOffsetY;
}

class _AddProductImageDialogState extends State<_AddProductImageDialog> {
  late final TextEditingController _controller;
  late final FocusNode _urlFocusNode;
  Uint8List? _imageBytes;
  _AddImageMethod? _imageMethod;
  bool _isReadingImage = false;
  String? _imageError;
  late double _imageScale;
  late double _imageOffsetX;
  late double _imageOffsetY;
  late final double _savedImageScale;
  late final double _savedImageOffsetX;
  late final double _savedImageOffsetY;
  bool _hasUrlSource = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _urlFocusNode = FocusNode();
    _savedImageScale = widget.product.imageScale.clamp(
      ProductImageFrame.minScale,
      ProductImageFrame.maxScale,
    );
    _savedImageOffsetX = widget.product.imageOffsetX.clamp(
      -ProductImageFrame.maxOffset,
      ProductImageFrame.maxOffset,
    );
    _savedImageOffsetY = widget.product.imageOffsetY.clamp(
      -ProductImageFrame.maxOffset,
      ProductImageFrame.maxOffset,
    );
    _restoreSavedImageView();
    _controller.addListener(_handleUrlChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleUrlChanged)
      ..dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteImage() async {
    _urlFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _isReadingImage = true;
      _imageError = null;
    });
    try {
      final bytes = await Pasteboard.image;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Clipboard does not contain an image.');
      }
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _imageBytes = bytes;
        _imageMethod = _AddImageMethod.clipboard;
        _imageError = null;
        _fitNewImage();
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _imageError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isReadingImage = false);
      }
    }
  }

  Future<void> _pickImage() async {
    _urlFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _isReadingImage = true;
      _imageError = null;
    });
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('Selected image is empty.');
      }
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _imageBytes = bytes;
        _imageMethod = _AddImageMethod.library;
        _imageError = null;
        _fitNewImage();
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _imageError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isReadingImage = false);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageMethod = null;
      _imageError = null;
      _restoreSavedImageView();
    });
  }

  void _fitNewImage() {
    _imageScale = ProductImageFrame.initialFittedScale;
    _imageOffsetX = 0;
    _imageOffsetY = 0;
  }

  void _restoreSavedImageView() {
    _imageScale = _savedImageScale;
    _imageOffsetX = _savedImageOffsetX;
    _imageOffsetY = _savedImageOffsetY;
  }

  void _handleUrlChanged() {
    final hasUrlSource = _controller.text.trim().isNotEmpty;
    setState(() {
      if (hasUrlSource && !_hasUrlSource) {
        _fitNewImage();
      } else if (!hasUrlSource && _hasUrlSource && _imageBytes == null) {
        _restoreSavedImageView();
      }
      _hasUrlSource = hasUrlSource;
    });
  }

  void _resetImageView() => setState(_fitNewImage);

  void _submit() {
    _urlFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    final bytes = _imageBytes;
    if (bytes != null && bytes.isNotEmpty) {
      Navigator.pop(
        context,
        _AddProductImageResult(
          _imageMethod!,
          imageBytes: bytes,
          imageScale: _imageScale,
          imageOffsetX: _imageOffsetX,
          imageOffsetY: _imageOffsetY,
        ),
      );
      return;
    }

    final imageUrl = _controller.text.trim();
    Navigator.pop(
      context,
      _AddProductImageResult(
        imageUrl.isEmpty ? _AddImageMethod.current : _AddImageMethod.url,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        imageScale: _imageScale,
        imageOffsetX: _imageOffsetX,
        imageOffsetY: _imageOffsetY,
      ),
    );
  }

  Widget? _previewImage() {
    final bytes = _imageBytes;
    if (bytes != null) {
      return ProductImageFrame(
        scale: _imageScale,
        offsetX: _imageOffsetX,
        offsetY: _imageOffsetY,
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    final imageUrl = _controller.text.trim();
    final uri = Uri.tryParse(imageUrl);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      return ProductImageFrame(
        scale: _imageScale,
        offsetX: _imageOffsetX,
        offsetY: _imageOffsetY,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder:
              (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
        ),
      );
    }

    final imageName = widget.product.imageName.trim();
    if (imageName.isEmpty || imageName == 'question') return null;
    return ProductImageView(
      imageName: imageName,
      scale: _imageScale,
      offsetX: _imageOffsetX,
      offsetY: _imageOffsetY,
      fallbackBuilder:
          (context) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
    );
  }

  Widget _imageViewSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) => Row(
    children: [
      SizedBox(width: 82, child: Text(label)),
      Expanded(
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final imageBytes = _imageBytes;
    final preview = _previewImage();
    final hasCurrentImage =
        widget.product.imageName.trim().isNotEmpty &&
        widget.product.imageName != 'question';
    final canSave =
        imageBytes != null ||
        _controller.text.trim().isNotEmpty ||
        hasCurrentImage;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final previewSize = math.min(screenWidth * 0.48, screenWidth * 0.95 * 0.58);

    return AlertDialog(
      title: Text(hasCurrentImage ? 'Edit product image' : 'Add product image'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste an image, choose one from your phone library, or add an '
              'image link.',
            ),
            const SizedBox(height: 12),
            if (preview != null) ...[
              Text(
                'Target checker preview',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _imageOffsetX = (_imageOffsetX +
                              details.delta.dx / previewSize)
                          .clamp(-0.5, 0.5);
                      _imageOffsetY = (_imageOffsetY +
                              details.delta.dy / previewSize)
                          .clamp(-0.5, 0.5);
                    });
                  },
                  child: Stack(
                    children: [
                      SizedBox.square(dimension: previewSize, child: preview),
                      if (imageBytes != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filledTonal(
                            tooltip: 'Use existing image',
                            onPressed: _removeImage,
                            icon: const Icon(Icons.close),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Drag the image or use the controls below.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              _imageViewSlider(
                label: 'Size ${(_imageScale * 100).round()}%',
                value: _imageScale,
                min: ProductImageFrame.minScale,
                max: ProductImageFrame.maxScale,
                onChanged: (value) => setState(() => _imageScale = value),
              ),
              _imageViewSlider(
                label: 'Left/right',
                value: _imageOffsetX,
                min: -0.5,
                max: 0.5,
                onChanged: (value) => setState(() => _imageOffsetX = value),
              ),
              _imageViewSlider(
                label: 'Up/down',
                value: _imageOffsetY,
                min: -0.5,
                max: 0.5,
                onChanged: (value) => setState(() => _imageOffsetY = value),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _resetImageView,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Fit with margin'),
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (_imageError != null) ...[
              Text(
                _imageError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isReadingImage ? null : _pasteImage,
                    icon: _ImageSourceButtonIcon(
                      isLoading: _isReadingImage,
                      icon: Icons.content_paste,
                    ),
                    label: const Text('Paste'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isReadingImage ? null : _pickImage,
                    icon: _ImageSourceButtonIcon(
                      isLoading: _isReadingImage,
                      icon: Icons.photo_library_outlined,
                    ),
                    label: const Text('Library'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'or use a link',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _controller,
              focusNode: _urlFocusNode,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              enabled: imageBytes == null,
              decoration: const InputDecoration(
                labelText: 'Image link',
                hintText: 'https://...',
              ),
              onTapOutside: (_) => _urlFocusNode.unfocus(),
              onSubmitted: (_) {
                if (canSave) _submit();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: canSave && !_isReadingImage ? _submit : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ImageSourceButtonIcon extends StatelessWidget {
  const _ImageSourceButtonIcon({required this.isLoading, required this.icon});

  final bool isLoading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return Icon(icon);
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _ImageToolsRow extends StatelessWidget {
  const _ImageToolsRow({
    required this.imageName,
    required this.isSaving,
    required this.onAddImage,
  });

  final String imageName;
  final bool isSaving;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageName.trim().isNotEmpty && imageName != 'question';
    return Row(
      children: [
        Icon(
          hasImage ? Icons.image_outlined : Icons.hide_image_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasImage ? imageName.trim() : 'No image assigned',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        TextButton.icon(
          onPressed: isSaving ? null : onAddImage,
          icon:
              isSaving
                  ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(hasImage ? 'Edit image' : 'Add image'),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.date, required this.bonus});
  final DateTime date;
  final double bonus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final divider = theme.dividerColor.withValues(alpha: 0.20);
    final primary = theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Amount pill (compact, high contrast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withValues(alpha: 0.45)),
              ),
              child: Text(
                '£ ${bonus.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Date, subtle
            Expanded(
              child: Text(
                DateFormat.yMMMd().format(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionToolbar extends StatelessWidget {
  const _DescriptionToolbar({required this.onInsert});
  final void Function(String text) onInsert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipStyle = theme.textTheme.labelSmall;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children:
          [
                const _QuickChip(label: '• bullet', insert: '• '),
                const _QuickChip(label: 'Tip:', insert: 'Tip: '),
                const _QuickChip(label: 'Note:', insert: 'Note: '),
              ]
              .map(
                (c) => ActionChip(
                  label: Text(c.label, style: chipStyle),
                  onPressed: () => onInsert(c.insert),
                ),
              )
              .toList(),
    );
  }
}

class _QuickChip {
  const _QuickChip({required this.label, required this.insert});
  final String label;
  final String insert;
}

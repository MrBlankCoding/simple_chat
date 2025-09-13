import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/constants.dart';

class ProfileImagePicker extends StatefulWidget {
  final Function(File?) onImageSelected;
  final Function()? onImageRemoved;
  final String? currentImageUrl;
  final File? selectedImage;
  final double size;

  const ProfileImagePicker({
    super.key,
    required this.onImageSelected,
    this.onImageRemoved,
    this.currentImageUrl,
    this.selectedImage,
    this.size = 100,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final ImagePicker _imagePicker = ImagePicker();

  void _showImageSourceDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Profile Picture'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Choose from Gallery'),
          ),
          if (widget.selectedImage != null || widget.currentImageUrl != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _removeImage();
              },
              isDestructiveAction: true,
              child: const Text('Remove Photo'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        widget.onImageSelected(File(image.path));
      }
    } catch (e) {
      // Handle error silently or show a toast
    }
  }

  void _removeImage() {
    widget.onImageSelected(null);
    if (widget.onImageRemoved != null) {
      widget.onImageRemoved!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppConstants.surfaceColor,
          border: Border.all(
            color: CupertinoColors.separator,
            width: 1,
          ),
        ),
        child: ClipOval(
          child: _buildImageWidget(),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (widget.selectedImage != null) {
      return Image.file(
        widget.selectedImage!,
        fit: BoxFit.cover,
      );
    } else if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return Image.network(
        widget.currentImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppConstants.surfaceColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.camera,
            size: widget.size * 0.3,
            color: CupertinoColors.secondaryLabel,
          ),
          const SizedBox(height: 4),
          Text(
            'Add Photo',
            style: TextStyle(
              fontSize: widget.size * 0.12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

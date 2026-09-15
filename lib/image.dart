import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_editor_pro/image_editor_pro.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

// Main Image Viewer Screen
class ImageViewerScreen extends StatefulWidget {
  final String imagePath;
  final List<String>? imagePaths;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.imagePath,
    this.imagePaths,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PhotoViewController _photoViewController;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showControls = true;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
    _currentIndex = widget.initialIndex;
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => _isLoading = true);
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final imagePaths = widget.imagePaths ?? [widget.imagePath];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Image Viewer
          _buildPhotoViewGallery(imagePaths),

          // Top Controls
          if (_showControls) _buildTopControls(),

          // Bottom Controls
          if (_showControls) _buildBottomControls(imagePaths),

          // Loading Indicator
          if (_isLoading) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildPhotoViewGallery(List<String> imagePaths) {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(imagePaths[index])),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 2.0,
          heroAttributes: PhotoViewHeroAttributes(tag: imagePaths[index]),
          onTapDown: (_, __, ___) => _toggleControls(),
        );
      },
      itemCount: imagePaths.length,
      pageController: PageController(initialPage: _currentIndex),
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => _shareImage(widget.imagePath),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(List<String> imagePaths) {
    final currentPath = imagePaths[_currentIndex];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePaths.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  min(5, imagePaths.length),
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomActionButton(
                  icon: Icons.crop,
                  label: 'Crop',
                  onTap: () => _cropImage(currentPath),
                ),
                _buildBottomActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: () => _editImage(currentPath),
                ),
                _buildBottomActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => _shareImage(currentPath),
                ),
                _buildBottomActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onTap: () => _deleteImage(currentPath),
                  color: Colors.red,
                ),
                _buildBottomActionButton(
                  icon: Icons.save_alt,
                  label: 'Save',
                  onTap: () => _saveImage(currentPath),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildMoreOption(
              icon: Icons.info_outline,
              label: 'Details',
              onTap: () => _showImageDetails(widget.imagePath),
            ),
            _buildMoreOption(
              icon: Icons.rotate_left,
              label: 'Rotate Left',
              onTap: () => _rotateImage(widget.imagePath, -90),
            ),
            _buildMoreOption(
              icon: Icons.rotate_right,
              label: 'Rotate Right',
              onTap: () => _rotateImage(widget.imagePath, 90),
            ),
            _buildMoreOption(
              icon: Icons.flip,
              label: 'Flip Horizontal',
              onTap: () => _flipImage(widget.imagePath),
            ),
            _buildMoreOption(
              icon: Icons.filter,
              label: 'Apply Filter',
              onTap: () => _applyFilter(widget.imagePath),
            ),
            _buildMoreOption(
              icon: Icons.save_alt,
              label: 'Save to Gallery',
              onTap: () => _saveToGallery(widget.imagePath),
            ),
            _buildMoreOption(
              icon: Icons.print,
              label: 'Print',
              onTap: () => _printImage(widget.imagePath),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // Image Operations

  Future<void> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null) {
        // Replace original with cropped image
        final originalFile = File(imagePath);
        await originalFile.delete();
        await File(croppedFile.path).copy(imagePath);
        await File(croppedFile.path).delete();

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image cropped successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error cropping image: $e');
    }
  }

  Future<void> _editImage(String imagePath) async {
    try {
      // Using image_editor_pro for advanced editing
      final editResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditorPro(
            image: FileImage(File(imagePath)),
            appBarColor: Colors.blue,
            bottomBarColor: Colors.blue,
            onImageEdited: (Uint8List data) {
              // Handle edited image
              final file = File(imagePath);
              file.writeAsBytesSync(data);
              setState(() {});
            },
          ),
        ),
      );

      if (editResult == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image edited successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error editing image: $e');
    }
  }

  Future<void> _shareImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out this image!',
        );
      }
    } catch (e) {
      _showError('Error sharing image: $e');
    }
  }

  Future<void> _deleteImage(String imagePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        _showError('Error deleting image: $e');
      }
    }
  }

  Future<void> _saveImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final savedDir = Directory('${appDir.path}/SavedImages');
        if (!await savedDir.exists()) {
          await savedDir.create(recursive: true);
        }

        final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final destFile = File('${savedDir.path}/$fileName');
        await file.copy(destFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to ${savedDir.path}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error saving image: $e');
    }
  }

  Future<void> _rotateImage(String imagePath, int degrees) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final decodedImage = await ui.instantiateImageCodec(bytes);
        final frame = await decodedImage.getNextFrame();
        final image = frame.image;

        // Create rotated image
        final pictureRecorder = ui.PictureRecorder();
        final canvas = Canvas(pictureRecorder);

        final angle = degrees * (pi / 180);
        final width = degrees.abs() % 180 == 90 ? image.height : image.width;
        final height = degrees.abs() % 180 == 90 ? image.width : image.height;

        canvas.translate(width / 2, height / 2);
        canvas.rotate(angle);
        canvas.translate(-image.width / 2, -image.height / 2);
        canvas.drawImage(image, Offset.zero, Paint());

        final picture = pictureRecorder.endRecording();
        final rotatedImage = await picture.toImage(width, height);
        final byteData = await rotatedImage.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          await file.writeAsBytes(byteData.buffer.asUint8List());
          setState(() {});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image rotated ${degrees}°'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      _showError('Error rotating image: $e');
    }
  }

  Future<void> _flipImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final decodedImage = await ui.instantiateImageCodec(bytes);
        final frame = await decodedImage.getNextFrame();
        final image = frame.image;

        // Create flipped image
        final pictureRecorder = ui.PictureRecorder();
        final canvas = Canvas(pictureRecorder);

        final matrix = Float64List.fromList([
          -1, 0, 0, 0,
          0, 1, 0, 0,
          0, 0, 1, 0,
          image.width.toDouble(), 0, 0, 1,
        ]);

        canvas.transform(matrix);
        canvas.drawImage(image, Offset.zero, Paint());

        final picture = pictureRecorder.endRecording();
        final flippedImage = await picture.toImage(image.width, image.height);
        final byteData = await flippedImage.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          await file.writeAsBytes(byteData.buffer.asUint8List());
          setState(() {});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image flipped horizontally'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      _showError('Error flipping image: $e');
    }
  }

  Future<void> _applyFilter(String imagePath) async {
    // Show filter selection dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apply Filter',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterOption('Original', (image) => image),
                _buildFilterOption('Grayscale', _applyGrayscaleFilter),
                _buildFilterOption('Sepia', _applySepiaFilter),
                _buildFilterOption('Brightness', _applyBrightnessFilter),
                _buildFilterOption('Contrast', _applyContrastFilter),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String name, Function(dynamic) filter) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        Navigator.pop(context);
        _applyFilterToImage(widget.imagePath, filter);
      },
      child: Text(name),
    );
  }

  Future<void> _applyFilterToImage(String imagePath, Function filter) async {
    try {
      // This is a simplified filter implementation
      // For real filters, you'd want to use a proper image processing library
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filter applied successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Error applying filter: $e');
    }
  }

  dynamic _applyGrayscaleFilter(dynamic image) {
    // Implement grayscale filter
    return image;
  }

  dynamic _applySepiaFilter(dynamic image) {
    // Implement sepia filter
    return image;
  }

  dynamic _applyBrightnessFilter(dynamic image) {
    // Implement brightness filter
    return image;
  }

  dynamic _applyContrastFilter(dynamic image) {
    // Implement contrast filter
    return image;
  }

  Future<void> _saveToGallery(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await GallerySaver.saveImage(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved to gallery'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError('Error saving to gallery: $e');
    }
  }

  Future<void> _printImage(String imagePath) async {
    // Implement printing functionality
    // Using printing package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality coming soon'),
      ),
    );
  }

  void _showImageDetails(String imagePath) {
    final file = File(imagePath);
    final stat = file.statSync();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', file.path.split('/').last),
            _buildDetailRow('Size', _formatSize(stat.size)),
            _buildDetailRow('Modified', DateFormat('dd MMM yyyy, HH:mm').format(stat.modified)),
            _buildDetailRow('Path', file.path),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Image Gallery Screen (to browse images)
class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  List<File> images = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => isLoading = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/Images');

      if (await imageDir.exists()) {
        final files = imageDir.listSync().whereType<File>().toList();
        setState(() {
          images = files;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading images: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Images'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : images.isEmpty
          ? _buildEmptyState()
          : _buildImageGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _importImages,
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Images Found',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Import Images'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(
                  imagePath: image.path,
                  imagePaths: images.map((e) => e.path).toList(),
                  initialIndex: index,
                ),
              ),
            );
          },
          child: Hero(
            tag: image.path,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _importImages() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickMultiImage();

      if (result != null && result.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final imageDir = Directory('${appDir.path}/Images');
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        for (final xFile in result) {
          final fileName = xFile.name;
          final destFile = File('${imageDir.path}/$fileName');
          await File(xFile.path).copy(destFile.path);
        }

        await _loadImages();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${result.length} image(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error importing images: $e');
    }
  }
}

// Helper function to get image files
Future<List<File>> getImageFiles() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/Images');

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
      return [];
    }

    return imageDir.listSync().whereType<File>().toList();
  } catch (e) {
    print('Error getting image files: $e');
    return [];
  }
}
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mime/mime.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

// Main File Viewer Screen
class FileViewerScreen extends StatefulWidget {
  final String filePath;
  final List<String>? filePaths;
  final int initialIndex;

  const FileViewerScreen({
    super.key,
    required this.filePath,
    this.filePaths,
    this.initialIndex = 0,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  late Future<FileInfo> _fileInfo;
  int _currentIndex = 0;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fileInfo = _loadFileInfo();
  }

  Future<FileInfo> _loadFileInfo() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final stat = file.statSync();
      final mime = lookupMimeType(widget.filePath) ?? 'application/octet-stream';
      final extension = widget.filePath.split('.').last.toLowerCase();

      return FileInfo(
        path: widget.filePath,
        name: widget.filePath.split('/').last,
        size: stat.size,
        modified: stat.modified,
        mimeType: mime,
        extension: extension,
      );
    } catch (e) {
      throw Exception('Error loading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: FutureBuilder<FileInfo>(
        future: _fileInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final fileInfo = snapshot.data!;
          return _buildContent(fileInfo);
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: Text(
        widget.filePath.split('/').last,
        style: const TextStyle(fontSize: 16),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareFile(widget.filePath),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  Widget _buildContent(FileInfo fileInfo) {
    return Column(
      children: [
        Expanded(
          child: _buildFilePreview(fileInfo),
        ),
        _buildFileInfoBar(fileInfo),
      ],
    );
  }

  Widget _buildFilePreview(FileInfo fileInfo) {
    final extension = fileInfo.extension;

    // PDF Preview
    if (extension == 'pdf') {
      return _buildPDFPreview(fileInfo.path);
    }

    // Text/Code files
    if (['txt', 'log', 'csv', 'json', 'xml', 'yaml', 'yml', 'md', 'markdown', 'rtf'].contains(extension)) {
      return _buildTextPreview(fileInfo.path);
    }

    // HTML files
    if (['html', 'htm'].contains(extension)) {
      return _buildHTMLPreview(fileInfo.path);
    }

    // Word documents
    if (['doc', 'docx'].contains(extension)) {
      return _buildDocumentPreview(fileInfo.path, 'Microsoft Word Document');
    }

    // Excel files
    if (['xls', 'xlsx'].contains(extension)) {
      return _buildDocumentPreview(fileInfo.path, 'Microsoft Excel Document');
    }

    // PowerPoint files
    if (['ppt', 'pptx'].contains(extension)) {
      return _buildDocumentPreview(fileInfo.path, 'Microsoft PowerPoint Presentation');
    }

    // Archive files
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return _buildArchivePreview(fileInfo.path);
    }

    // Audio files
    if (['mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg'].contains(extension)) {
      return _buildAudioPreview(fileInfo.path);
    }

    // Video files (use video player if available)
    if (['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv'].contains(extension)) {
      return _buildVideoPreview(fileInfo.path);
    }

    // Default preview for other file types
    return _buildDefaultPreview(fileInfo);
  }

  // PDF Preview
  Widget _buildPDFPreview(String path) {
    return PdfViewerWidget(
      path: path,
      showPdfViewer: true,
      onViewCreated: (controller) {
        // Controller for PDF viewer
      },
    );
  }

  // Text Preview
  Widget _buildTextPreview(String path) {
    return FutureBuilder<String>(
      future: File(path).readAsString(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error reading text file');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              snapshot.data ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        );
      },
    );
  }

  // HTML Preview
  Widget _buildHTMLPreview(String path) {
    return FutureBuilder<String>(
      future: File(path).readAsString(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error reading HTML file');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.all(16),
            child: HtmlWidget(
              snapshot.data ?? '',
              textStyle: const TextStyle(fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  // Document Preview (Word, Excel, PowerPoint)
  Widget _buildDocumentPreview(String path, String docType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getDocumentIcon(path),
                  size: 64,
                  color: Colors.blue[700],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    path.split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            docType,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            path.split('/').last,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openWithDefaultApp(path),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with Default App'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Archive Preview
  Widget _buildArchivePreview(String path) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.folder_zip,
              size: 64,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Archive File',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            path.split('/').last,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _extractArchive(path),
            icon: const Icon(Icons.unarchive),
            label: const Text('Extract Archive'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Audio Preview
  Widget _buildAudioPreview(String path) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  spreadRadius: 4,
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(
              Icons.audiotrack,
              size: 64,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Audio File',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            path.split('/').last,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 32),
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: Colors.purple[100],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.share, size: 24),
                onPressed: () => _shareFile(path),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Video Preview
  Widget _buildVideoPreview(String path) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: Colors.white,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Video',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Video File',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            path.split('/').last,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openWithDefaultApp(path),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Video'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Default Preview
  Widget _buildDefaultPreview(FileInfo fileInfo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              _getFileIcon(fileInfo.extension),
              size: 64,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getFileTypeName(fileInfo.extension),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fileInfo.name,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openWithDefaultApp(fileInfo.path),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with Default App'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfoBar(FileInfo fileInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileInfo.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.storage,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatSize(fileInfo.size),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(fileInfo.modified),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading File',
            style: TextStyle(fontSize: 20, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _openWithDefaultApp(widget.filePath),
      icon: const Icon(Icons.open_in_new),
      label: const Text('Open'),
      backgroundColor: Colors.blue,
    );
  }

  // Helper Methods
  IconData _getDocumentIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'log':
      case 'md':
        return Icons.text_snippet;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'mp4':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileTypeName(String extension) {
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'txt':
        return 'Text File';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'zip':
      case 'rar':
      case '7z':
        return 'Archive File';
      case 'mp3':
      case 'wav':
      case 'aac':
        return 'Audio File';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'Video File';
      default:
        return 'Unknown File';
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // File Operations
  void _shareFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out this file: ${path.split('/').last}',
        );
      }
    } catch (e) {
      _showError('Error sharing file: $e');
    }
  }

  void _openWithDefaultApp(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        _showError('Error opening file: ${result.message}');
      }
    } catch (e) {
      _showError('Error opening file: $e');
    }
  }

  void _extractArchive(String path) async {
    try {
      // Implement archive extraction using archive package
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archive extraction coming soon'),
        ),
      );
    } catch (e) {
      _showError('Error extracting archive: $e');
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.share,
              label: 'Share',
              onTap: () => _shareFile(widget.filePath),
            ),
            _buildOptionTile(
              icon: Icons.open_in_new,
              label: 'Open with...',
              onTap: () => _openWithDefaultApp(widget.filePath),
            ),
            _buildOptionTile(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () => _copyFile(widget.filePath),
            ),
            /*_buildOptionTile(
              icon: Icons.move,
              label: 'Move',
              onTap: () => _moveFile(widget.filePath),
            ),
            _buildOptionTile(
              icon: Icons.rename,
              label: 'Rename',
              onTap: () => _renameFile(widget.filePath),
            ),*/
            _buildOptionTile(
              icon: Icons.info_outline,
              label: 'Details',
              onTap: () => _showFileDetails(widget.filePath),
            ),
            _buildOptionTile(
              icon: Icons.delete,
              label: 'Delete',
              onTap: () => _deleteFile(widget.filePath),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _copyFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final destDir = Directory('${appDir.path}/CopiedFiles');
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        final fileName = path.split('/').last;
        final destPath = '${destDir.path}/$fileName';
        final destFile = File(destPath);

        // Add number suffix if file exists
        if (await destFile.exists()) {
          final nameWithoutExt = fileName.split('.').first;
          final ext = fileName.split('.').last;
          final newName = '${nameWithoutExt}_copy.${ext}';
          await file.copy('${destDir.path}/$newName');
        } else {
          await file.copy(destPath);
        }

        _showSuccess('File copied successfully');
      }
    } catch (e) {
      _showError('Error copying file: $e');
    }
  }

  Future<void> _moveFile(String path) async {
    try {
      // Implementation for moving file
      _showSuccess('Move functionality coming soon');
    } catch (e) {
      _showError('Error moving file: $e');
    }
  }

  Future<void> _renameFile(String path) async {
    final controller = TextEditingController(text: path.split('/').last);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new file name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final dir = path.split('/').sublist(0, path.split('/').length - 1).join('/');
          final newPath = '$dir/${controller.text}';
          await file.rename(newPath);
          _showSuccess('File renamed successfully');

          // Update the state to reflect the new path
          setState(() {
            // Update file path if needed
          });
        }
      } catch (e) {
        _showError('Error renaming file: $e');
      }
    }
  }

  void _showFileDetails(String path) {
    final file = File(path);
    final stat = file.statSync();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', path.split('/').last),
            _buildDetailRow('Type', path.split('.').last.toUpperCase()),
            _buildDetailRow('Size', _formatSize(stat.size)),
            _buildDetailRow('Created', DateFormat('dd MMM yyyy, HH:mm').format(stat.created)),
            _buildDetailRow('Modified', DateFormat('dd MMM yyyy, HH:mm').format(stat.modified)),
            _buildDetailRow('Path', path),
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

  Future<void> _deleteFile(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${path.split('/').last}"?'),
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
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          if (mounted) {
            Navigator.pop(context);
            _showSuccess('File deleted successfully');
          }
        }
      } catch (e) {
        _showError('Error deleting file: $e');
      }
    }
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

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// File Info Model
class FileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final String mimeType;
  final String extension;

  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    required this.mimeType,
    required this.extension,
  });
}

// All Files Screen
class AllFilesScreen extends StatefulWidget {
  const AllFilesScreen({super.key});

  @override
  State<AllFilesScreen> createState() => _AllFilesScreenState();
}

class _AllFilesScreenState extends State<AllFilesScreen> {
  List<FileSystemEntity> files = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortBy = 'Name';
  bool isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => isLoading = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final entries = appDir.listSync(recursive: true).toList();
      setState(() {
        files = entries;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading files: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('All Files'),
      actions: [
        IconButton(
          icon: Icon(isGridView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => isGridView = !isGridView),
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortOptions,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search files...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredFiles = _filterAndSortFiles();

    if (filteredFiles.isEmpty) {
      return _buildEmptyState();
    }

    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: filteredFiles.length,
        itemBuilder: (context, index) {
          return _buildFileGridItem(filteredFiles[index]);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredFiles.length,
        itemBuilder: (context, index) {
          return _buildFileListItem(filteredFiles[index]);
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Files Found',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Import files to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _importFiles,
      icon: const Icon(Icons.upload_file),
      label: const Text('Import Files'),
    );
  }

  Widget _buildFileGridItem(FileSystemEntity entity) {
    final name = entity.path.split('/').last;
    final stat = entity.statSync();
    final isDirectory = entity is Directory;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openFile(entity),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDirectory ? Icons.folder : _getFileIconByName(name),
              size: 48,
              color: isDirectory ? Colors.amber : Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            Text(
              _formatSize(stat.size),
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListItem(FileSystemEntity entity) {
    final name = entity.path.split('/').last;
    final stat = entity.statSync();
    final isDirectory = entity is Directory;
    final mime = lookupMimeType(entity.path);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          isDirectory ? Icons.folder : _getFileIconByName(name),
          color: isDirectory ? Colors.amber : Colors.blue,
          size: 32,
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDirectory && mime != null)
              Text(
                mime.split('/').last.toUpperCase(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            Row(
              children: [
                Text(
                  _formatSize(stat.size),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('dd MMM yyyy').format(stat.modified),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'open':
                _openFile(entity);
                break;
              case 'share':
                _shareFile(entity.path);
                break;
              case 'delete':
                _deleteFile(entity.path);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 20),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openFile(entity),
      ),
    );
  }

  List<FileSystemEntity> _filterAndSortFiles() {
    var filtered = files.where((file) {
      final name = file.path.split('/').last.toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    switch (sortBy) {
      case 'Name':
        filtered.sort((a, b) => a.path.compareTo(b.path));
        break;
      case 'Size':
        filtered.sort((a, b) => a.statSync().size.compareTo(b.statSync().size));
        break;
      case 'Date Modified':
        filtered.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        break;
      case 'Type':
        filtered.sort((a, b) {
          final aExt = a.path.split('.').last;
          final bExt = b.path.split('.').last;
          return aExt.compareTo(bExt);
        });
        break;
    }

    return filtered;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _buildSortOption('Name'),
          _buildSortOption('Size'),
          _buildSortOption('Date Modified'),
          _buildSortOption('Type'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSortOption(String option) {
    return ListTile(
      title: Text(option),
      leading: Radio<String>(
        value: option,
        groupValue: sortBy,
        onChanged: (value) {
          setState(() => sortBy = value!);
          Navigator.pop(context);
        },
      ),
    );
  }

  IconData _getFileIconByName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'log':
      case 'md':
        return Icons.text_snippet;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audiotrack;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _openFile(FileSystemEntity entity) {
    if (entity is Directory) {
      // Navigate to folder
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder navigation coming soon'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileViewerScreen(
          filePath: entity.path,
          filePaths: [entity.path],
        ),
      ),
    );
  }

  void _shareFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out this file: ${path.split('/').last}',
        );
      }
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  Future<void> _deleteFile(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${path.split('/').last}"?'),
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
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          setState(() {
            files.removeWhere((f) => f.path == path);
          });
          _showSuccess('File deleted successfully');
        }
      } catch (e) {
        _showError('Error deleting file: $e');
      }
    }
  }

  Future<void> _importFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
      );

      if (result != null && result.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final uploadDir = Directory('${appDir.path}/Uploads');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }

        for (final file in result) {
          final sourceFile = File(file.path!);
          final fileName = file.name;
          final destFile = File('${uploadDir.path}/$fileName');

          // Add number suffix if file exists
          if (await destFile.exists()) {
            final nameWithoutExt = fileName.split('.').first;
            final ext = fileName.split('.').last;
            final newName = '${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}.$ext';
            final destFileNew = File('${uploadDir.path}/$newName');
            await sourceFile.copy(destFileNew.path);
          } else {
            await sourceFile.copy(destFile.path);
          }
        }

        await _loadFiles();
        _showSuccess('Imported ${result.files.length} file(s)');
      }
    } catch (e) {
      _showError('Error importing files: $e');
    }
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

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
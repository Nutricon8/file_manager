import 'dart:io';
import 'dart:math';

import 'package:file_manager/main2.dart';
import 'package:file_manager/main3.dart';
import 'package:file_manager/video.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';

void main() => runApp(const FileManagerApp());

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced File Manager',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const VideoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<StorageInfo> storageInfo;
  late Future<List<FileSystemEntity>> recentFiles;
  late Future<Map<String, List<FileSystemEntity>>> categorizedFiles;
  final List<Folder> folders = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    storageInfo = getStorageInfo();
    recentFiles = getRecentFiles();
    categorizedFiles = getCategorizedFiles();
    _initFolders();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  void _initFolders() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDocDir.path}/Downloads');
    final dcimDir = Directory('/storage/emulated/0/DCIM');
    final documentsDir = Directory('${appDocDir.path}/Documents');
    final musicDir = Directory('${appDocDir.path}/Music');

    folders.addAll([
      Folder(name: 'Office Trip', path: dcimDir.path, itemCount: 16),
      Folder(name: 'Downloads', path: downloadsDir.path, itemCount: 14),
      Folder(name: 'Documents', path: documentsDir.path, itemCount: 5),
      Folder(name: 'Music', path: musicDir.path, itemCount: 20),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([storageInfo, recentFiles, categorizedFiles]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final StorageInfo info = snapshot.data![0];
          final List<FileSystemEntity> recents = snapshot.data![1];
          final Map<String, List<FileSystemEntity>> categorized =
              snapshot.data![2];

          return _buildContent(info, recents, categorized);
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildContent(
    StorageInfo info,
    List<FileSystemEntity> recents,
    Map<String, List<FileSystemEntity>> categorized,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStorageOverview(info),
          const SizedBox(height: 24),
          _buildCategories(categorized),
          const SizedBox(height: 24),
          _buildFoldersSection(),
          const SizedBox(height: 24),
          _buildRecentFiles(recents),
          const SizedBox(height: 24),
          _buildStorageDetails(info, categorized),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hi Vaishali",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Manage all your files and apps",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStorageOverview(StorageInfo info) {
    final usedPercent = info.totalSpace > 0
        ? info.usedSpace / info.totalSpace
        : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Device Storage",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      "${_formatBytes(info.freeSpace)} Free",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    CircularPercentIndicator(
                      radius: 12,
                      lineWidth: 3,
                      percent: usedPercent.toDouble(),
                      backgroundColor: Colors.grey[300]!,
                      progressColor: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              padding: EdgeInsets.zero,
              lineHeight: 8,
              percent: usedPercent.toDouble(),
              backgroundColor: Colors.grey[300],
              progressColor: Colors.blue,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatBytes(info.usedSpace)),
                Text(_formatBytes(info.totalSpace)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(Map<String, List<FileSystemEntity>> categorized) {
    final categories = [
      {
        'name': 'Photos',
        'icon': Icons.photo,
        'files': categorized['image'] ?? [],
      },
      {
        'name': 'Videos',
        'icon': Icons.video_collection,
        'files': categorized['video'] ?? [],
      },
      {
        'name': 'Documents',
        'icon': Icons.description,
        'files': categorized['document'] ?? [],
      },
      {
        'name': 'Audio',
        'icon': Icons.audiotrack,
        'files': categorized['audio'] ?? [],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Categories",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              final size = _calculateCategorySize(
                category['files'] as List<FileSystemEntity>,
              );
              return CategoryCard(
                icon: category['icon'] as IconData,
                name: category['name']!.toString(), //name: category['name']!,
                size: _formatBytes(size),
                count: (category['files'] as List).length,
                onTap: () => _openCategory(
                  context,
                  category['name']!.toString() /*category['name']!*/,
                  category['files'] as List<FileSystemEntity>,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoldersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "My Folders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text("View All")),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return FolderCard(
              icon: Icons.folder,
              name: folder.name,
              count: '${folder.itemCount} items',
              onTap: () => _openFolder(context, folder),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentFiles(List<FileSystemEntity> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Files",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text("View All")),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: min(5, files.length),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final file = files[index];
            final stat = file.statSync();
            return FileItemCard(
              entity: file,
              onTap: () => _openFile(context, file),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStorageDetails(
    StorageInfo info,
    Map<String, List<FileSystemEntity>> categorized,
  ) {
    final total = info.totalSpace;
    final categories = [
      {
        'name': 'Images',
        'files': categorized['image'] ?? [],
        'color': Colors.blue,
      },
      {
        'name': 'Videos',
        'files': categorized['video'] ?? [],
        'color': Colors.green,
      },
      {
        'name': 'Documents',
        'files': categorized['document'] ?? [],
        'color': Colors.orange,
      },
      {
        'name': 'Audio',
        'files': categorized['audio'] ?? [],
        'color': Colors.purple,
      },
      {
        'name': 'Other',
        'files': categorized['other'] ?? [],
        'color': Colors.red,
      },
    ];

    // Calculate percentages
    final List<Map<String, dynamic>> storageCategories = categories.map((
      category,
    ) {
      final size = _calculateCategorySize(
        category['files'] as List<FileSystemEntity>,
      );
      final percent = total > 0 ? size / total : 0;
      return {
        'name': category['name'],
        'size': size,
        'percent': percent,
        'color': category['color'],
      };
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Storage Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatBytes(info.totalSpace),
                  /*Text("${_formatBytes(info.freeSpace)} Free | ${_formatBytes(info.usedSpace)} Used", 
                    style: const TextStyle(color: Colors.grey)*/
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStorageBar(storageCategories),
            const SizedBox(height: 16),
            ...storageCategories.map((category) {
              return _buildStorageCategoryItem(
                category['name']!,
                category['percent']!,
                _formatBytes(category['size']!),
                category['color']!,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBar(List<Map<String, dynamic>> categories) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          for (final category in categories)
            Flexible(
              flex: (category['percent'] * 1000).round(),
              child: Container(
                decoration: BoxDecoration(
                  color: category['color'],
                  borderRadius: _getBarRadius(category, categories),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageCategoryItem(
    String name,
    double percent,
    String size,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text("${(percent * 100).toStringAsFixed(1)}% ($size)"),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
        BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Storage'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  // Helper methods
  String _formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  int _calculateCategorySize(List<FileSystemEntity> files) {
    return files.fold<int>(0, (sum, file) {
      try {
        return sum + file.statSync().size;
      } catch (e) {
        return sum;
      }
    });
  }

  BorderRadius _getBarRadius(
    Map<String, dynamic> category,
    List<Map<String, dynamic>> allCategories,
  ) {
    final index = allCategories.indexOf(category);
    if (allCategories.length == 1) return BorderRadius.circular(4);

    if (index == 0) {
      return const BorderRadius.only(
        topLeft: Radius.circular(4),
        bottomLeft: Radius.circular(4),
      );
    } else if (index == allCategories.length - 1) {
      return const BorderRadius.only(
        topRight: Radius.circular(4),
        bottomRight: Radius.circular(4),
      );
    }
    return BorderRadius.zero;
  }

  // Navigation methods
  void _openCategory(
    BuildContext context,
    String category,
    List<FileSystemEntity> files,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoryScreen(categoryName: category, files: files),
      ),
    );
  }

  void _openFolder(BuildContext context, Folder folder) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FolderScreen(folder: folder)),
    );
  }

  void _openFile(BuildContext context, FileSystemEntity file) {
    // Implement file opening logic based on file type
    // For example: use open_file package to open files
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Selected'),
        content: Text('You selected: ${file.path.split('/').last}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Data Models
class StorageInfo {
  final int totalSpace;
  final int usedSpace;
  final int freeSpace;

  StorageInfo({
    required this.totalSpace,
    required this.usedSpace,
    required this.freeSpace,
  });
}

class Folder {
  final String name;
  final String path;
  final int itemCount;

  Folder({required this.name, required this.path, required this.itemCount});
}

// FIXED STORAGE INFO RETRIEVAL
Future<StorageInfo> getStorageInfo() async {
  try {
    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      final root = directory.parent.parent;
      final stat = root.statSync();

      // For platforms that support statfs
      if (stat is FileSystemEntity) {
        final total = await _getTotalSpace(root.path);
        final free = await _getFreeSpace(root.path);
        return StorageInfo(
          totalSpace: total,
          usedSpace: total - free,
          freeSpace: free,
        );
      }
    }

    // Fallback for unsupported platforms
    return StorageInfo(
      totalSpace: 512 * 1024 * 1024 * 1024, // 512 GB
      usedSpace: (69.8 * 1024 * 1024 * 1024).toInt(), // 69.8 GB
      freeSpace: ((512 - 69.8) * 1024 * 1024 * 1024).toInt(),
    );
  } catch (e) {
    return StorageInfo(
      totalSpace: 512 * 1024 * 1024 * 1024,
      usedSpace: (69.8 * 1024 * 1024 * 1024).toInt(),
      freeSpace: ((512 - 69.8) * 1024 * 1024 * 1024).toInt(),
    );
  }
}

// Platform-specific storage space retrieval
Future<int> _getTotalSpace(String path) async {
  if (Platform.isAndroid || Platform.isIOS) {
    // For Android, we can use the storage path to get stats
    try {
      final process = await Process.run('df', [path]);
      final output = process.stdout.toString();
      final lines = output.split('\n');

      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length > 1) {
          final size = int.parse(parts[1]) * 1024; // Convert from KB to bytes
          return size;
        }
      }
    } catch (e) {
      print('Error getting total space: $e');
    }
  }

  // Default value if unable to retrieve
  return 512 * 1024 * 1024 * 1024; // 512 GB
}

Future<int> _getFreeSpace(String path) async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final process = await Process.run('df', [path]);
      final output = process.stdout.toString();
      final lines = output.split('\n');

      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length > 3) {
          final free = int.parse(parts[3]) * 1024; // Convert from KB to bytes
          return free;
        }
      }
    } catch (e) {
      print('Error getting free space: $e');
    }
  }

  // Default value if unable to retrieve
  return ((512 - 69.8) * 1024 * 1024 * 1024).toInt();
}

Future<List<FileSystemEntity>> getRecentFiles() async {
  final directory = await getApplicationDocumentsDirectory();
  final downloadsDir = Directory('${directory.path}/Downloads');

  if (!await downloadsDir.exists()) {
    await downloadsDir.create(recursive: true);
  }

  final files = downloadsDir.listSync().whereType<File>().toList();
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files.take(10).toList();
}

Future<Map<String, List<FileSystemEntity>>> getCategorizedFiles() async {
  final directory = await getApplicationDocumentsDirectory();
  final downloadsDir = Directory('${directory.path}/Downloads');
  final dcimDir = Directory('/storage/emulated/0/DCIM');
  final musicDir = Directory('${directory.path}/Music');

  // Create directories if they don't exist
  for (final dir in [downloadsDir, dcimDir, musicDir]) {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  final allFiles = <FileSystemEntity>[];
  allFiles.addAll(downloadsDir.listSync(recursive: true));
  allFiles.addAll(dcimDir.listSync(recursive: true));
  allFiles.addAll(musicDir.listSync(recursive: true));

  final Map<String, List<FileSystemEntity>> categorized = {
    'image': [],
    'video': [],
    'audio': [],
    'document': [],
    'other': [],
  };

  for (final file in allFiles) {
    if (file is File) {
      final mime = lookupMimeType(file.path);
      if (mime != null) {
        if (mime.startsWith('image/')) {
          categorized['image']!.add(file);
        } else if (mime.startsWith('video/')) {
          categorized['video']!.add(file);
        } else if (mime.startsWith('audio/')) {
          categorized['audio']!.add(file);
        } else if (mime == 'application/pdf' ||
            mime == 'application/msword' ||
            mime == 'application/vnd.ms-excel') {
          categorized['document']!.add(file);
        } else {
          categorized['other']!.add(file);
        }
      } else {
        categorized['other']!.add(file);
      }
    }
  }

  return categorized;
}

// UI Components
class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String size;
  final int count;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.name,
    required this.size,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                "$count files",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                size,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolderCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String count;
  final VoidCallback? onTap;

  const FolderCard({
    super.key,
    required this.icon,
    required this.name,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.amber),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    count,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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

class FileItemCard extends StatelessWidget {
  final FileSystemEntity entity;
  final VoidCallback? onTap;

  const FileItemCard({super.key, required this.entity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fileName = entity.path.split('/').last;
    final stat = entity.statSync();
    final size = stat.size;
    final modified = stat.modified;
    final dateFormat = DateFormat('dd MMM. yyyy');

    IconData icon;
    if (entity is Directory) {
      icon = Icons.folder;
    } else {
      final mime = lookupMimeType(entity.path);
      if (mime?.startsWith('image/') ?? false) {
        icon = Icons.image;
      } else if (mime?.startsWith('video/') ?? false) {
        icon = Icons.video_file;
      } else if (mime?.startsWith('audio/') ?? false) {
        icon = Icons.audiotrack;
      } else if (mime == 'application/pdf') {
        icon = Icons.picture_as_pdf;
      } else {
        icon = Icons.insert_drive_file;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          title: Text(fileName),
          subtitle: Text(
            "${_formatBytes(size)} • ${dateFormat.format(modified)}",
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFileOptions(context, entity),
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _showFileOptions(BuildContext context, FileSystemEntity entity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () {
              Navigator.pop(context);
              if (onTap != null) onTap!();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // Implement share functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _deleteFile(context, entity);
            },
          ),
        ],
      ),
    );
  }

  void _deleteFile(BuildContext context, FileSystemEntity entity) async {
    try {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else if (entity is File) {
        await entity.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting file: $e')));
    }
  }
}

// Category Screen
class CategoryScreen extends StatelessWidget {
  final String categoryName;
  final List<FileSystemEntity> files;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    required this.files,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          return FileItemCard(
            entity: files[index],
            onTap: () => _openFile(context, files[index]),
          );
        },
      ),
    );
  }

  void _openFile(BuildContext context, FileSystemEntity file) {
    // Implement file opening logic
  }
}

// Folder Screen
class FolderScreen extends StatefulWidget {
  final Folder folder;

  const FolderScreen({super.key, required this.folder});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late Future<List<FileSystemEntity>> contents;

  @override
  void initState() {
    super.initState();
    contents = _loadContents();
  }

  Future<List<FileSystemEntity>> _loadContents() async {
    final dir = Directory(widget.folder.path);
    if (await dir.exists()) {
      return dir.list().toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      body: FutureBuilder(
        future: contents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Folder is empty'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return FileItemCard(
                entity: items[index],
                onTap: () {
                  if (items[index] is Directory) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FolderScreen(
                          folder: Folder(
                            name: items[index].path.split('/').last,
                            path: items[index].path,
                            itemCount: 0, // Will be loaded later
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Open file
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFile,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addFile() async {
    // Implement file creation logic
  }
}

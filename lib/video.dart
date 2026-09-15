import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

// Main Video Screen
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  List<VideoFile> videos = [];
  bool isLoading = true;
  String searchQuery = '';
  bool isGridView = false;
  String sortBy = 'Date Modified';

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => isLoading = true);
    try {
      // Request permission if needed
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Handle permission denial
          setState(() => isLoading = false);
          return;
        }
      }

      final videosList = await getVideoFiles();
      setState(() {
        videos = videosList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading videos: $e');
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
      title: const Text('Videos'),
      actions: [
        IconButton(
          icon: Icon(isGridView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => isGridView = !isGridView),
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortOptions,
        ),
        IconButton(
          icon: const Icon(Icons.upload),
          onPressed: _importVideo,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search videos...',
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

    final filteredVideos = _filterAndSortVideos();

    if (filteredVideos.isEmpty) {
      return _buildEmptyState();
    }

    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: filteredVideos.length,
        itemBuilder: (context, index) {
          return VideoGridItem(
            video: filteredVideos[index],
            onTap: () => _openVideoPlayer(filteredVideos[index]),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredVideos.length,
        itemBuilder: (context, index) {
          return VideoListItem(
            video: filteredVideos[index],
            onTap: () => _openVideoPlayer(filteredVideos[index]),
            onDelete: () => _deleteVideo(filteredVideos[index]),
            onShare: () => _shareVideo(filteredVideos[index]),
          );
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Videos Found',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Import videos to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importVideo,
            icon: const Icon(Icons.upload),
            label: const Text('Import Video'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _importVideo,
      icon: const Icon(Icons.video_call),
      label: const Text('Import'),
    );
  }

  List<VideoFile> _filterAndSortVideos() {
    var filtered = videos.where((video) {
      return video.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    switch (sortBy) {
      case 'Name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Date Modified':
        filtered.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case 'Size':
        filtered.sort((a, b) => b.size.compareTo(a.size));
        break;
      case 'Duration':
        filtered.sort((a, b) => b.duration.compareTo(a.duration));
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
          _buildSortOption('Date Modified'),
          _buildSortOption('Size'),
          _buildSortOption('Duration'),
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
          setState(() {
            sortBy = value!;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openVideoPlayer(VideoFile video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoFile: video),
      ),
    );
  }

  Future<void> _importVideo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null && result.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final videoDir = Directory('${appDir.path}/Videos');
        if (!await videoDir.exists()) {
          await videoDir.create(recursive: true);
        }

        for (final file in result) {
          final sourceFile = File(file.path!);
          final fileName = file.name;
          final destFile = File('${videoDir.path}/$fileName');

          // Copy file to app directory
          await sourceFile.copy(destFile.path);
        }

        // Refresh the video list
        await _loadVideos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${result.length} video(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error importing video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing videos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(VideoFile video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${video.name}"?'),
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
        final file = File(video.path);
        if (await file.exists()) {
          await file.delete();
          setState(() {
            videos.removeWhere((v) => v.path == video.path);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        print('Error deleting video: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting video: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareVideo(VideoFile video) async {
    try {
      final file = File(video.path);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out this video: ${video.name}',
        );
      }
    } catch (e) {
      print('Error sharing video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Video Data Model
class VideoFile {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final Duration duration;
  final String thumbnailPath;

  VideoFile({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.duration,
    required this.thumbnailPath,
  });
}

// Service to get video files
Future<List<VideoFile>> getVideoFiles() async {
  final List<VideoFile> videos = [];

  try {
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/Videos');

    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
      return videos;
    }

    final files = videoDir.listSync().whereType<File>().toList();

    for (final file in files) {
      final mime = lookupMimeType(file.path);
      if (mime != null && mime.startsWith('video/')) {
        final stat = file.statSync();
        final duration = await _getVideoDuration(file.path);

        videos.add(VideoFile(
          name: file.path.split('/').last,
          path: file.path,
          size: stat.size,
          modified: stat.modified,
          duration: duration,
          thumbnailPath: '', // Will be generated when needed
        ));
      }
    }

    // Sort by date modified (most recent first)
    videos.sort((a, b) => b.modified.compareTo(a.modified));

  } catch (e) {
    print('Error getting video files: $e');
  }

  return videos;
}

Future<Duration> _getVideoDuration(String path) async {
  try {
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();
    return duration;
  } catch (e) {
    return Duration.zero;
  }
}

// Video Grid Item Widget
class VideoGridItem extends StatelessWidget {
  final VideoFile video;
  final VoidCallback onTap;

  const VideoGridItem({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    // Video thumbnail placeholder
                    Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 48,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    // Duration badge
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatSize(video.size),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}

// Video List Item Widget
class VideoListItem extends StatelessWidget {
  final VideoFile video;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const VideoListItem({
    super.key,
    required this.video,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(video.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          video.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatSize(video.size),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(video.modified),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'play':
                onTap();
                break;
              case 'share':
                onShare();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  SizedBox(width: 8),
                  Text('Play'),
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
        onTap: onTap,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}

// Video Player Screen
class VideoPlayerScreen extends StatefulWidget {
  final VideoFile videoFile;

  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.videoFile.path));
      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        //systemOverlaysAfterFullScreen: [ui.SystemUiOverlay.all],
        aspectRatio: _videoController.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey[300]!,
          bufferedColor: Colors.blue[200]!,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing player: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoFile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                final file = File(widget.videoFile.path);
                if (await file.exists()) {
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: 'Check out this video: ${widget.videoFile.name}',
                  );
                }
              } catch (e) {
                print('Error sharing: $e');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: Chewie(controller: _chewieController),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.videoFile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        '${widget.videoFile.duration.inMinutes}:${(widget.videoFile.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      ),
                      avatar: const Icon(Icons.timer, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_formatSize(widget.videoFile.size)),
                      avatar: const Icon(Icons.storage, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        DateFormat('dd MMM yyyy').format(widget.videoFile.modified),
                      ),
                      avatar: const Icon(Icons.calendar_today, size: 16),
                    ),
                  ],
                ),
              ],
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
}
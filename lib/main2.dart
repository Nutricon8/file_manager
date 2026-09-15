import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
//import 'package:vector_math/vector_math.dart' as math;


class HomeScreen1 extends StatelessWidget {
  const HomeScreen1({super.key});

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStorageOverview(),
              const SizedBox(height: 24),
              _buildCategories(),
              const SizedBox(height: 24),
              _buildFoldersSection(),
              const SizedBox(height: 24),
              _buildRecentFiles(),
              const SizedBox(height: 24),
              _buildStorageDetails(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hi Vaishali", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text("Manage all your files and apps", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildStorageOverview() {
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
                const Text("Google Drive", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Text("100 Documents", style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    CircularPercentIndicator(
                      radius: 12,
                      lineWidth: 3,
                      percent: 0.25,
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
              percent: 0.25,
              backgroundColor: Colors.grey[300],
              progressColor: Colors.blue,
              barRadius: const Radius.circular(4),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("38 GB"),
                Text("15 GB"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.photo, 'name': 'Photos', 'size': '20.8 GB'},
      {'icon': Icons.video_collection, 'name': 'Videos', 'size': '29 GB'},
      {'icon': Icons.description, 'name': 'Documents', 'size': '8 GB'},
      {'icon': Icons.audiotrack, 'name': 'Audio', 'size': '12 GB'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryCard(
                icon: category['icon'] as IconData,
                name: category['name']! as String,
                size: category['size']! as String,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoldersSection() {
    final folders = [
      {'name': 'Documents', 'count': '32 Files', 'icon': Icons.folder},
      {'name': 'UI Design', 'count': '24 Files', 'icon': Icons.folder_special},
      {'name': 'Music', 'count': '20 items', 'icon': Icons.folder},
      {'name': 'Downloads', 'count': '14 items', 'icon': Icons.download},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("My Folders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text("View All"),
            ),
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
              icon: folder['icon'] as IconData,
              name: folder['name']! as String,
              count: folder['count']! as String,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentFiles() {
    final files = [
      {'name': 'Twilight movie.mp4', 'size': '1.3 GB', 'date': '23 Oct. 2022', 'icon': Icons.video_file},
      {'name': 'IMG2546.jpg', 'size': '12.1 MB', 'date': '24 Jan. 2023', 'icon': Icons.image},
      {'name': 'Balancesheet.xls', 'size': '3.5 MB', 'date': '15 Mar. 2023', 'icon': Icons.description},
      {'name': 'Invitation Card.pdf', 'size': '2.3 KB', 'date': '30 Apr. 2023', 'icon': Icons.picture_as_pdf},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Files", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: files.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final file = files[index];
            return FileItemCard(
              icon: file['icon'] as IconData,
              name: file['name']! as String,
              size: file['size']! as String,
              date: file['date']! as String,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStorageDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Storage", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("128 GB", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("95 GB Free | 33 GB Used", style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            _buildStorageBar(),
            const SizedBox(height: 16),
            _buildStorageCategories(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBar() {
    return Stack(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: 0.25,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageCategories() {
    final categories = [
      {'name': 'Images', 'percent': 0.35, 'color': Colors.blue},
      {'name': 'Videos', 'percent': 0.25, 'color': Colors.green},
      {'name': 'Documents', 'percent': 0.20, 'color': Colors.orange},
      {'name': 'Music', 'percent': 0.15, 'color': Colors.purple},
      {'name': 'Downloads', 'percent': 0.05, 'color': Colors.red},
    ];

    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: category['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(category['name'] as String),
              ),
              Text("${((category['percent'] as double) * 100).toInt()}%"),
            ],
          ),
        );
      }).toList(),
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
}

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String size;

  const CategoryCard({super.key, 
    required this.icon,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
            Text(size, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class FolderCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String count;

  const FolderCard({super.key, 
    required this.icon,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(count, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FileItemCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String size;
  final String date;

  const FileItemCard({super.key, 
    required this.icon,
    required this.name,
    required this.size,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
        title: Text(name),
        subtitle: Text("$size • $date"),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TaskScreen extends StatefulWidget {
  final bool isArabic;

  const TaskScreen({super.key, required this.isArabic});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Genre> genres = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchGenres();
  }

  Future<void> fetchGenres() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://animetower-backend.7modo.com/api/v1/genres'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        setState(() {
          genres = data.map((json) => Genre.fromJson(json)).toList();
        });
      }
    } catch (e) {
      showError(
          widget.isArabic ? 'حدث خطأ في جلب الأنواع' : 'Error fetching genres');
    }
    setState(() => isLoading = false);
  }

  Future<void> addGenre(String name, String description) async {
    try {
      final response = await http.post(
        Uri.parse('https://animetower-backend.7modo.com/api/v1/genres'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        fetchGenres();
      }
    } catch (e) {
      showError(
          widget.isArabic ? 'حدث خطأ في إضافة النوع' : 'Error adding genre');
    }
  }

  Future<void> updateGenre(int id, String name, String description) async {
    try {
      final response = await http.put(
        Uri.parse('https://animetower-backend.7modo.com/api/v1/genres/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        fetchGenres();
      }
    } catch (e) {
      showError(
          widget.isArabic ? 'حدث خطأ في تحديث النوع' : 'Error updating genre');
    }
  }

  Future<void> deleteGenre(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('https://animetower-backend.7modo.com/api/v1/genres/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        fetchGenres();
      }
    } catch (e) {
      showError(
          widget.isArabic ? 'حدث خطأ في حذف النوع' : 'Error deleting genre');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showGenreDialog({Genre? genre}) {
    final nameController = TextEditingController(text: genre?.name);
    final descriptionController =
        TextEditingController(text: genre?.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(genre == null
            ? (widget.isArabic ? 'إضافة مهمة جديدة' : 'Add New Task')
            : (widget.isArabic ? 'تعديل المهمة' : 'Edit Task')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: widget.isArabic ? 'عنوان المهمة' : 'Task Title',
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: widget.isArabic ? 'وصف المهمة' : 'Task Description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (genre == null) {
                addGenre(nameController.text, descriptionController.text);
              } else {
                updateGenre(
                    genre.id, nameController.text, descriptionController.text);
              }
              Navigator.pop(context);
            },
            child: Text(widget.isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? 'المهام اليومية' : 'Daily Tasks'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(genre.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(genre.description),
                        Text(
                          widget.isArabic
                              ? ': ${genre.animeCount}'
                              : ': ${genre.animeCount}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => showGenreDialog(genre: genre),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => deleteGenre(genre.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showGenreDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Genre {
  final int id;
  final String name;
  final String description;
  final int animeCount;

  Genre({
    required this.id,
    required this.name,
    required this.description,
    required this.animeCount,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      animeCount: json['anime_count'] ?? 0,
    );
  }
}

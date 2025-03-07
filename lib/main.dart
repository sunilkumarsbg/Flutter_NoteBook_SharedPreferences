import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Model
class Note {
  int id;
  String title;
  String description;

  Note({required this.id, required this.title, required this.description});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'description': description};
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
        id: map['id'], title: map['title'], description: map['description']);
  }
}

// Controller
class NoteController extends GetxController {
  var notes = <Note>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  void loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? notesString = prefs.getString('notes');
    if (notesString != null) {
      List<dynamic> decoded = jsonDecode(notesString);
      notes.value = decoded.map((e) => Note.fromMap(e)).toList();
    }
  }

  void saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> mappedNotes = notes.map((e) => e.toMap()).toList();
    prefs.setString('notes', jsonEncode(mappedNotes));
  }

  void addNote(String title, String description) {
    int id = notes.isEmpty ? 1 : notes.last.id + 1;
    notes.add(Note(id: id, title: title, description: description));
    saveNotes();
  }

  void updateNote(Note note) {
    int index = notes.indexWhere((element) => element.id == note.id);
    if (index != -1) {
      notes[index] = note;
      saveNotes();
    }
  }

  void deleteNote(int id) {
    notes.removeWhere((note) => note.id == id);
    saveNotes();
  }
}

// UI
class NotesScreen extends StatelessWidget {
  final NoteController controller = Get.put(NoteController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("To-Do Notes")),
      body: Obx(() => ListView.builder(
        itemCount: controller.notes.length,
        itemBuilder: (context, index) {
          var note = controller.notes[index];
          return ListTile(
            title: Text(note.title),
            subtitle: Text(note.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showNoteDialog(context, note)),
                IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => controller.deleteNote(note.id)),
              ],
            ),
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showNoteDialog(context),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, [Note? note]) {
    var titleController = TextEditingController(text: note?.title ?? "");
    var descController = TextEditingController(text: note?.description ?? "");

    showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(note == null ? "Add Note" : "Edit Note"),
          content: Column(
            children: [
              CupertinoTextField(controller: titleController, placeholder: "Title"),
              CupertinoTextField(controller: descController, placeholder: "Description"),
            ],
          ),
          actions: [
            CupertinoDialogAction(
                child: const Text("Cancel"),
                onPressed: () => Get.back()),
            CupertinoDialogAction(
                child: const Text("Save"),
                onPressed: () {
                  if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                    if (note == null) {
                      controller.addNote(titleController.text, descController.text);
                    } else {
                      controller.updateNote(Note(
                          id: note.id,
                          title: titleController.text,
                          description: descController.text));
                    }
                  }
                  Get.back();
                }),
          ],
        ));
  }
}

void main() {
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    home: NotesScreen(),
  ));
}

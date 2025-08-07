import 'package:flutter/material.dart';

import '../design_repository_class.dart';

class NotePage extends StatefulWidget {
  const NotePage({Key? key}) : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late NoteRepositoryProvider _provider;
  late Future<NoteRepository> _repositoryFuture;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = NoteRepositoryProvider(); // 預設 Auto Mode
    _repositoryFuture = _provider.getRepository();
  }

  void _saveNote() async {
    final repo = await _repositoryFuture;
    final result = await repo.save(Note(id: 0, title: _textController.text));

    result.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save Failed: ${failure.message}'))),
            (note) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save Success: ${note.title}')))
    );

    _textController.clear();
  }

  void _softDelete(int id) async {
    final repo = await _repositoryFuture;
    final result = await repo.softDelete(id);

    result.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete Failed: ${failure.message}'))),
            (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete Success')))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notes')),
      body: FutureBuilder<NoteRepository>(
        future: _repositoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }

          final repository = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(labelText: 'New Note'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _saveNote,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Note>>(
                  stream: repository.watchAll(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final notes = snapshot.data!;
                    return ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return ListTile(
                          title: Text(note.title),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _softDelete(note.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

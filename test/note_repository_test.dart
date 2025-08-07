import 'package:flutter_practice/design_repository_class.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('LocalNoteRepository Tests', () {
    sharedRepositoryTests(() => LocalNoteRepository());
  });

  group('RemoteNoteRepository Tests', () {
    sharedRepositoryTests(() => RemoteNoteRepository());
  });
}

/// 共用的測試邏輯
void sharedRepositoryTests(NoteRepository Function() repoBuilder) {
  late NoteRepository repo;

  setUp(() async {
    repo = repoBuilder();
  });

  group('正常情況', () {
    test('watchAll() should emit notes list', () async {
      final notesStream = repo.watchAll();
      final notes = await notesStream.first;

      expect(notes, isA<List<Note>>()); // 確保有回傳一個 List<Note>
      expect(notes, isNotNull);         // 確保不是 null
    });

    test('save() should insert a new note', () async {
      final result = await repo.save(Note(id: 0, title: 'New Note'));
      expect(result.isRight(), true);
      result.fold((_) => fail('Should not fail'), (note) {
        expect(note.id, greaterThan(0)); // save時，當id不存在Notes中，則會自動編流水號，故返回時id > 0
        expect(note.title, 'New Note');
      });
    });

    test('save() should update note if id already exists', () async {
      // Arrange: 先新增一筆筆記
      final insertResult = await repo.save(Note(id: 0, title: 'Original Note'));
      final originalNote = insertResult.getOrElse(() => throw Exception('Insert failed'));

      // Act: 將該筆筆記的 title 改為 Updated Note 並再次 save
      final updateResult = await repo.save(Note(id: originalNote.id, title: 'Updated Note'));
      final updatedNote = updateResult.getOrElse(() => throw Exception('Update failed'));

      // Assert: 確認 id 沒變，title 被更新
      expect(updatedNote.id, originalNote.id);
      expect(updatedNote.title, 'Updated Note');

      // 再次檢查 watchAll() 確認該筆資料有被更新
      final notes = await repo.watchAll().first;
      final matchedNotes = notes.where((n) => n.id == originalNote.id).toList();
      expect(matchedNotes.length, 1);
      expect(matchedNotes.first.title, 'Updated Note');
    });

    test('softDelete() should mark note as deleted', () async {
      // Arrange: 先新增一筆筆記
      final insertResult = await repo.save(Note(id: 0, title: 'Note to be deleted'));
      final noteToDelete = insertResult.getOrElse(() => throw Exception('Insert failed'));

      // Act: 軟刪除該筆筆記
      final deleteResult = await repo.softDelete(noteToDelete.id);
      expect(deleteResult.isRight(), true);

      // Assert: 確認該筆筆記已被軟刪除
      final notes = await repo.watchAll().first;
      final deletedNote = notes.where((n) => n.id == noteToDelete.id).toList();
      expect(deletedNote.isEmpty, true); // 軟刪除後該筆記不應出現
    });

  });

  group('錯誤情境', () {
    test('save() should return failure when title is empty', () async {
      final result = await repo.save(Note(id: 0, title: ''));
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure.message, contains('Title cannot be empty'));
      }, (_) => fail('Should not succeed'));
    });

    test('softDelete() should return failure when id not found', () async {
      final deleteResult = await repo.softDelete(-1);
      expect(deleteResult.isLeft(), true);
      deleteResult.fold((failure) {
        expect(failure.message, contains('Note not found'));
      }, (_) => fail('Should not succeed'));
    });
  });

  group('邊界情境', () {
    test('save() with extremely long title', () async {
      final longTitle = 'A' * 1000;
      final result = await repo.save(Note(id: 0, title: longTitle));
      expect(result.isRight(), true);
      result.fold((_) => fail('Should not fail'), (note) {
        expect(note.title.length, 1000);
      });
    });

    test('softDelete() multiple times on same id', () async {
      // insert 一筆
      final insertResult = await repo.save(Note(id: 0, title: 'Note for multiple delete test'));
      final newNote = insertResult.getOrElse(() => throw Exception('Insert failed'));
      // First delete should succeed
      final firstDelete = await repo.softDelete(newNote.id);
      expect(firstDelete.isRight(), true);

      // Second delete on same id should fail (already deleted)
      final secondDelete = await repo.softDelete(newNote.id);
      expect(secondDelete.isLeft(), true);
      secondDelete.fold((failure) {
        expect(failure.message, contains('Note already deleted'));
      }, (_) => fail('Should not succeed'));
    });
  });
}
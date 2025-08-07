import 'dart:async';
import 'package:dartz/dartz.dart';

/// 定義 Note 類別
class Note {
  final int id;
  final String title;
  bool isDeleted;

  Note({
    required this.id,
    required this.title,
    this.isDeleted = false,
  });

  Note copyWith({required int id, String? title, bool? isDeleted}) {
    return Note(
      id: id,
      title: title ?? this.title,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
/// 定義 Failure 類別，用於處理錯誤情況
class Failure {
  final String message;
  Failure(this.message);
}

/// 模擬 SQLite 資料庫或 API 操作的假資料層
///
/// - 支援筆記的插入、新增/更新 (save)
/// - 軟刪除筆記 (softDelete)
/// - 透過 Stream 模擬 watchAll 監聽資料變化 (每2秒更新一次)
class FakeNoteDao {
  final List<Note> _notes = [
    Note(id: 1, title: 'Note 1'),
    Note(id: 2, title: 'Note 2'),
  ];

  final StreamController<List<Note>> _controller = StreamController.broadcast();

  FakeNoteDao() {
    _emitCurrentState();
  }

  void _emitCurrentState() {
    final activeNotes = _notes.where((n) => n.isDeleted == false).toList();
    _controller.add(activeNotes);
  }

  Stream<List<Note>> watchAll() {
    Timer.periodic(Duration(seconds: 2), (_) => _emitCurrentState());
    return _controller.stream;
  }

  Future<Note> insertOrUpdate(Note note) async {
    await Future.delayed(Duration(seconds: 2)); // 模擬DB延遲

    if (note.title.isEmpty) {
      throw Exception('Title cannot be empty');
    }

    if (note.id != 0) {
      // 嘗試更新
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        _emitCurrentState();
        return note;
      }
    }

    // 若找不到 id，則新增
    final newId = _notes.isNotEmpty ? _notes.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1 : 1;
    final newNote = note.copyWith(id: newId);
    _notes.add(newNote);
    _emitCurrentState();
    return newNote;
  }

  Future<void> softDelete(int id) async {
    await Future.delayed(Duration(seconds: 2)); // 模擬DB延遲
    final note = _notes.firstWhere((n) => n.id == id, orElse: () => throw Exception('Note not found')); // 找不到筆記則拋出異常
    if (note.isDeleted) {
      throw Exception('Note already deleted');
    }
    note.isDeleted = true;
    _emitCurrentState();
  }
}

/*
定義抽象 class NoteRepository:
Stream<List<Note>> watchAll()
Future<Either<Failure, Note>> save(Note note)
Future<Either<Failure, Unit>> softDelete(id)
*/
abstract class NoteRepository {
  /// 監聽所有筆記的變化
  Stream<List<Note>> watchAll();

  /// 儲存一個新的或更新的筆記
  Future<Either<Failure, Note>> save(Note note);

  /// 軟刪除指定 ID 的筆記
  Future<Either<Failure, Unit>> softDelete(int id);
}

// LocalNoteRepository 實作
class LocalNoteRepository implements NoteRepository {
  // 先用假Dao，實際上應該是調用本地資料庫
  final FakeNoteDao _dao = FakeNoteDao();

  @override
  Stream<List<Note>> watchAll() {
    return _dao.watchAll();
  }

  @override
  Future<Either<Failure, Note>> save(Note note) async {
    try {
      final newNote = await _dao.insertOrUpdate(note);
      return Right(newNote);
    } catch (e) {
      return Left(Failure('Failed to save note (local): $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> softDelete(int id) async {
    try {
      await _dao.softDelete(id);
      return const Right(unit);
    } catch (e) {
      return Left(Failure('Failed to delete note (local): $e'));
    }
  }
}

// remoteNoteRepository 實作
class RemoteNoteRepository implements NoteRepository {
  // 先用假Dao，實際上調用遠端服務的API
  final FakeNoteDao _dao = FakeNoteDao();

  @override
  Stream<List<Note>> watchAll() {
    return _dao.watchAll();
  }

  @override
  Future<Either<Failure, Note>> save(Note note) async {
    try {
      final newNote = await _dao.insertOrUpdate(note);
      return Right(newNote);
    } catch (e) {
      return Left(Failure('Failed to save note (remote): $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> softDelete(int id) async {
    try {
      await _dao.softDelete(id);
      return const Right(unit);
    } catch (e) {
      return Left(Failure('Failed to delete note (remote): $e'));
    }
  }
}

// 統一的入口點，根據網路狀態提供對應的 repository
class NoteRepositoryProvider {
  final LocalNoteRepository _localRepo = LocalNoteRepository();
  final RemoteNoteRepository _remoteRepo = RemoteNoteRepository();

  // 假設這個是你的「網路檢查」邏輯
  Future<bool> _isConnected() async {
    await Future.delayed(Duration(milliseconds: 500)); // 模擬檢查網路
    return true; // for demo
  }

  // 根據當前網路狀態切換使用的 repository
  Future<NoteRepository> getRepository() async {
    final connected = await _isConnected();
    if (connected) {
      print(' Using Remote Repository');
      return _remoteRepo;
    } else {
      print(' Using Local Repository');
      return _localRepo;
    }
  }
}

// 測試錯誤回傳
Future<void> main() async {
  final provider = NoteRepositoryProvider();
  final repo = await provider.getRepository(); // 根據網路狀態獲取對應的 repository
  // 嘗試儲存一個新筆記 title 為空的情況
  final result = await repo.save(Note(id: 0, title: ''));
  result.fold(
    (failure) => print('Save Failed: ${failure.message}'), // 會進這裡 -> Failed to save note (remote): Title cannot be empty
    (note) => print('Save Success: ${note.title}'),
  );
}

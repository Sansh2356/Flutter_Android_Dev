import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class DatabaseAlreadyOpenException implements Exception {}

class UnableToGetDocumentsDirectory implements Exception {}

class DatabaseIsNotOpen implements Exception {}

class CouldeNotDeleteUser implements Exception {}

class UserAlreadyExists implements Exception {}

class CouldNotFindUser implements Exception {}

class CouldNotfoundUser implements Exception {}

class CouldNotDeleteNote implements Exception {}

class CouldNotFindNote implements Exception {}

class CouldNotUpdateNote implements Exception {}

class NotesService {
  Database? _db;
  Future<DatabaseUser> createUser({required String email}) async {
    final db = getDatabaseOrThrow();
    final results = await db.query(
      usertable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty != true) {
      throw UserAlreadyExists();
    }
    final userId = await db.insert(usertable, {
      emailColumn: email.toLowerCase(),
    });
    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<DatabaseUser> getUser({required String email}) async {
    final db = getDatabaseOrThrow();
    final results = await db.query(
      usertable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return (DatabaseUser.fromRow(results.first));
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    final db = getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);
    //Make sure that the owner of the database exists with the correct email//
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    const text = '';
    //Create the notes//
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithServerColumn: 1,
    });
    final note = DatabaseNote(
        id: noteId, userId: owner.id, text: text, isSyncedWithServer: true);
    return note;
  }

  Future<void> deleteNote({required int id}) async {
    final db = getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id =?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    }
  }

  Future<int> deleteAllNotes() async {
    final db = getDatabaseOrThrow();
    return await db.delete(noteTable);
  }

  Future<DatabaseNote> getNote({required int id}) async {
    final db = getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id=?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      return DatabaseNote.fromRow(notes.first);
    }
  }

  Future<Iterable<DatabaseNote>> getAllNote() async {
    final db = getDatabaseOrThrow();
    final notes = await db.query(noteTable);
    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
  }

  Future<DatabaseNote> updateNote(
      {required DatabaseNote note, required String text}) async {
    final db = getDatabaseOrThrow();
    await getNote(id: note.id);
    final updateCounts = await db.update(noteTable, {
      textColumn: text,
      isSyncedWithServerColumn: 0,
    });
    if (updateCounts == 0) {
      throw CouldNotUpdateNote();
    } else {
      return await getNote(id: note.id);
    }
  }

  Future<void> deleteUser({required String email}) async {
    final db = getDatabaseOrThrow();
    final deletedCount = await db
        .delete(usertable, where: 'email=?', whereArgs: [email.toLowerCase()]);
    if (deletedCount != 1) {
      throw CouldeNotDeleteUser();
    }
  }

  Database getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      //Create user table;
      await db.execute(createUserTable);
      //Creation of note table//
      await db.execute(createNotetable);
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });
  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;
  @override
  String toString() => 'Person,ID = $id,email = $email';
  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithServer;
  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithServer,
  });
  //check again//
  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithServer =
            (map[isSyncedWithServerColumn] as int) == 1 ? true : false;
  @override
  String toString() =>
      'Note,ID = $id,userId = $userId,isSyncedWithServer = $isSyncedWithServer,text =$text';
  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const usertable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithServerColumn = 'is_synced_with_server';
const createNotetable = '''
CREATE TABLE IF NOT EXIST"note" (
	"id"	INTEGER NOT NULL,
	"user_id"	TEXT NOT NULL,
	"Text"	TEXT,
	"is_synced_with_server"	INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("user_id") REFERENCES "user"("id")
);
''';
const createUserTable = '''
CREATE TABLE IF NOT EXISTS"user"(
	"id"	INTEGER NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
''';

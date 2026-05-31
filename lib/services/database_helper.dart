import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grading_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        todoId TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        category TEXT,
        priority TEXT,
        dueDate TEXT,
        isCompleted INTEGER,
        createdAt TEXT,
        updatedAt TEXT,
        userId TEXT,
        isSynced INTEGER,
        isDeleted INTEGER
      )
    ''');
  }

  Future<void> insertOrUpdateTodo(TodoModel todo, String userId, {required int isSynced, required int isDeleted}) async {
    final db = await instance.database;

    final map = {
      'todoId': todo.todoId,
      'title': todo.title,
      'description': todo.description,
      'category': todo.category,
      'priority': todo.priority,
      'dueDate': todo.dueDate.toIso8601String(),
      'isCompleted': todo.isCompleted ? 1 : 0,
      'createdAt': todo.createdAt.toIso8601String(),
      'updatedAt': todo.updatedAt.toIso8601String(),
      'userId': userId,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
    };

    await db.insert(
      'todos',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TodoModel>> getActiveTodos(String userId) async {
    final db = await instance.database;

    final result = await db.query(
      'todos',
      where: 'userId = ? AND isDeleted = 0',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return result.map((json) {
      return TodoModel(
        todoId: json['todoId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        priority: json['priority'] as String,
        dueDate: DateTime.parse(json['dueDate'] as String),
        isCompleted: (json['isCompleted'] as int) == 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTodoRecords(String userId) async {
    final db = await instance.database;
    return await db.query(
      'todos',
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
  }

  Future<void> markAsSynced(String todoId) async {
    final db = await instance.database;
    await db.update(
      'todos',
      {'isSynced': 1},
      where: 'todoId = ?',
      whereArgs: [todoId],
    );
  }

  Future<void> markAsDeleted(String todoId) async {
    final db = await instance.database;
    await db.update(
      'todos',
      {'isDeleted': 1, 'isSynced': 0},
      where: 'todoId = ?',
      whereArgs: [todoId],
    );
  }

  Future<void> deleteTodoPermanently(String todoId) async {
    final db = await instance.database;
    await db.delete(
      'todos',
      where: 'todoId = ?',
      whereArgs: [todoId],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_model.dart';
import '../services/todo_service.dart';
import '../services/database_helper.dart';

class TodoProvider extends ChangeNotifier {
  final TodoService _todoService = TodoService();
  
  List<TodoModel> _todos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Pending', 'Completed', 'Due Today', 'Overdue'
  bool _sortByDueDateAsc = true;
  String? _currentUserId;

  StreamSubscription<List<TodoModel>>? _todoSubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  List<TodoModel> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  bool get sortByDueDateAsc => _sortByDueDateAsc;

  // Initialize and subscribe to Firestore updates
  void initialize(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    _loadLocalTodos().then((_) {
      _isLoading = false;
      notifyListeners();
    });

    _todoSubscription?.cancel();
    _todoSubscription = _todoService.getTodosStream(userId).listen(
      (todosList) {
        _mergeFirestoreTodos(todosList);
      },
      onError: (error) {
        debugPrint("Firestore stream subscription error: $error");
      },
    );

    _startSyncTimer();
  }

  // Load from local SQLite Database
  Future<void> _loadLocalTodos() async {
    if (_currentUserId == null) return;
    try {
      _todos = await DatabaseHelper.instance.getActiveTodos(_currentUserId!);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to load local tasks: $e";
      notifyListeners();
    }
  }

  // Merge items from remote Firestore into SQLite
  Future<void> _mergeFirestoreTodos(List<TodoModel> firestoreTodos) async {
    if (_currentUserId == null) return;
    final userId = _currentUserId!;
    final dbHelper = DatabaseHelper.instance;

    try {
      // Get active local todos
      final localTodos = await dbHelper.getActiveTodos(userId);
      final localMap = {for (var t in localTodos) t.todoId: t};
      
      // Get all unsynced database records to check if they are pending deletion
      final unsyncedRecords = await dbHelper.getUnsyncedTodoRecords(userId);
      final unsyncedDeletedIds = unsyncedRecords
          .where((r) => r['isDeleted'] == 1)
          .map((r) => r['todoId'] as String)
          .toSet();

      final firestoreIds = firestoreTodos.map((t) => t.todoId).toSet();

      // 1. Process items from Firestore
      for (final fTodo in firestoreTodos) {
        // Skip if it's pending deletion locally
        if (unsyncedDeletedIds.contains(fTodo.todoId)) continue;

        final localTodo = localMap[fTodo.todoId];
        if (localTodo != null) {
          // If local version has unsynced changes, do not overwrite it
          final db = await dbHelper.database;
          final localRecord = await db.query(
            'todos',
            where: 'todoId = ?',
            whereArgs: [fTodo.todoId],
          );
          if (localRecord.isNotEmpty) {
            final isSynced = localRecord.first['isSynced'] as int;
            if (isSynced == 0) {
              continue; // local unsynced change wins
            }
          }
        }
        
        // Otherwise, write Firestore version to SQLite as synced
        await dbHelper.insertOrUpdateTodo(fTodo, userId, isSynced: 1, isDeleted: 0);
      }

      // 2. Process items that were deleted on Firestore (but marked synced locally)
      for (final lTodo in localTodos) {
        if (!firestoreIds.contains(lTodo.todoId)) {
          // If it is marked synced, it means it was deleted on Firebase. Remove locally.
          final db = await dbHelper.database;
          final localRecord = await db.query(
            'todos',
            where: 'todoId = ?',
            whereArgs: [lTodo.todoId],
          );
          if (localRecord.isNotEmpty) {
            final isSynced = localRecord.first['isSynced'] as int;
            if (isSynced == 1) {
              await dbHelper.deleteTodoPermanently(lTodo.todoId);
            }
          }
        }
      }

      // 3. Reload local database to update UI
      await _loadLocalTodos();
    } catch (e) {
      debugPrint("Error merging Firestore todos: $e");
    }
  }

  // Periodic Timer setup
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      syncUnsyncedData();
    });
  }

  // Background sync task
  Future<void> syncUnsyncedData() async {
    if (_currentUserId == null || _isSyncing) return;
    
    // Check connection first
    final isOnline = await _todoService.checkConnectivity();
    if (!isOnline) return;

    _isSyncing = true;
    final userId = _currentUserId!;
    final dbHelper = DatabaseHelper.instance;

    try {
      // Find all unsynced records
      final unsynced = await dbHelper.getUnsyncedTodoRecords(userId);
      if (unsynced.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint("Syncing ${unsynced.length} unsynced items to Firestore...");

      for (final record in unsynced) {
        final todoId = record['todoId'] as String;
        final isDeleted = record['isDeleted'] as int;

        if (isDeleted == 1) {
          try {
            await _todoService.deleteTodo(userId, todoId);
            await dbHelper.deleteTodoPermanently(todoId);
          } catch (e) {
            debugPrint("Failed to sync deletion for $todoId: $e");
          }
        } else {
          final todo = TodoModel(
            todoId: todoId,
            title: record['title'] as String,
            description: record['description'] as String,
            category: record['category'] as String,
            priority: record['priority'] as String,
            dueDate: DateTime.parse(record['dueDate'] as String),
            isCompleted: (record['isCompleted'] as int) == 1,
            createdAt: DateTime.parse(record['createdAt'] as String),
            updatedAt: DateTime.parse(record['updatedAt'] as String),
          );

          try {
            await _todoService.addTodo(userId, todo);
            await dbHelper.markAsSynced(todoId);
          } catch (e) {
            debugPrint("Failed to sync todo $todoId: $e");
          }
        }
      }

      await _loadLocalTodos();
    } catch (e) {
      debugPrint("Error during data synchronization: $e");
    } finally {
      _isSyncing = false;
    }
  }

  // Clear state when user logs out
  void clear() {
    _todoSubscription?.cancel();
    _todoSubscription = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _todos = [];
    _currentUserId = null;
    _searchQuery = '';
    _selectedFilter = 'All';
    _sortByDueDateAsc = true;
  }

  // Setters for search and filter options
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void toggleSortOrder() {
    _sortByDueDateAsc = !_sortByDueDateAsc;
    notifyListeners();
  }

  // Add Task
  Future<void> addTodo(TodoModel todo) async {
    if (_currentUserId == null) return;
    final userId = _currentUserId!;

    final String todoId = todo.todoId.isEmpty
        ? FirebaseFirestore.instance.collection('users').doc(userId).collection('todos').doc().id
        : todo.todoId;

    final todoWithId = todo.copyWith(
      todoId: todoId,
      createdAt: todo.createdAt,
      updatedAt: DateTime.now(),
    );

    // Save locally first
    await DatabaseHelper.instance.insertOrUpdateTodo(todoWithId, userId, isSynced: 0, isDeleted: 0);
    await _loadLocalTodos();

    // Try immediately syncing
    final isOnline = await _todoService.checkConnectivity();
    if (isOnline) {
      try {
        await _todoService.addTodo(userId, todoWithId);
        await DatabaseHelper.instance.markAsSynced(todoId);
        await _loadLocalTodos();
      } catch (e) {
        debugPrint("Immediate sync failed for added todo, retrying in background: $e");
      }
    }
  }

  // Update Task
  Future<void> updateTodo(TodoModel todo) async {
    if (_currentUserId == null) return;
    final userId = _currentUserId!;

    final todoWithUpdatedTime = todo.copyWith(
      updatedAt: DateTime.now(),
    );

    // Save locally first
    await DatabaseHelper.instance.insertOrUpdateTodo(todoWithUpdatedTime, userId, isSynced: 0, isDeleted: 0);
    await _loadLocalTodos();

    // Try immediately syncing
    final isOnline = await _todoService.checkConnectivity();
    if (isOnline) {
      try {
        await _todoService.updateTodo(userId, todoWithUpdatedTime);
        await DatabaseHelper.instance.markAsSynced(todo.todoId);
        await _loadLocalTodos();
      } catch (e) {
        debugPrint("Immediate sync failed for updated todo, retrying in background: $e");
      }
    }
  }

  // Delete Task
  Future<void> deleteTodo(String todoId) async {
    if (_currentUserId == null) return;
    final userId = _currentUserId!;

    // Check if it's already unsynced (i.e. not yet in Firestore)
    final db = await DatabaseHelper.instance.database;
    final record = await db.query(
      'todos',
      where: 'todoId = ?',
      whereArgs: [todoId],
    );

    if (record.isNotEmpty) {
      final isSynced = record.first['isSynced'] as int;
      if (isSynced == 0) {
        // Was never synced to Firestore, delete permanently from local DB
        await DatabaseHelper.instance.deleteTodoPermanently(todoId);
        await _loadLocalTodos();
        return;
      }
    }

    // Mark as deleted locally
    await DatabaseHelper.instance.markAsDeleted(todoId);
    await _loadLocalTodos();

    // Try immediately syncing
    final isOnline = await _todoService.checkConnectivity();
    if (isOnline) {
      try {
        await _todoService.deleteTodo(userId, todoId);
        await DatabaseHelper.instance.deleteTodoPermanently(todoId);
        await _loadLocalTodos();
      } catch (e) {
        debugPrint("Immediate sync failed for deleted todo, retrying in background: $e");
      }
    }
  }

  // Complete/Incomplete Toggle
  Future<void> toggleComplete(TodoModel todo) async {
    final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);
    await updateTodo(updatedTodo);
  }

  // Filtering and Sorting logic
  List<TodoModel> get filteredAndSortedTodos {
    List<TodoModel> result = List.from(_todos);

    // Apply Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((todo) {
        return todo.title.toLowerCase().contains(query) ||
            todo.description.toLowerCase().contains(query);
      }).toList();
    }

    // Apply Filter
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case 'Pending':
        result = result.where((todo) => !todo.isCompleted).toList();
        break;
      case 'Completed':
        result = result.where((todo) => todo.isCompleted).toList();
        break;
      case 'Due Today':
        result = result.where((todo) {
          return todo.dueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
              todo.dueDate.isBefore(todayEnd.add(const Duration(seconds: 1)));
        }).toList();
        break;
      case 'Overdue':
        result = result.where((todo) {
          return !todo.isCompleted && todo.dueDate.isBefore(todayStart);
        }).toList();
        break;
      case 'All':
      default:
        break;
    }

    // Apply Sort (By Due Date)
    result.sort((a, b) {
      if (_sortByDueDateAsc) {
        return a.dueDate.compareTo(b.dueDate);
      } else {
        return b.dueDate.compareTo(a.dueDate);
      }
    });

    return result;
  }

  // Dashboard Stats
  int get totalTasksCount => _todos.length;
  int get completedTasksCount => _todos.where((todo) => todo.isCompleted).length;
  int get pendingTasksCount => _todos.where((todo) => !todo.isCompleted).length;
  double get completionPercentage {
    if (_todos.isEmpty) return 0.0;
    return (completedTasksCount / totalTasksCount) * 100;
  }

  // Category counts/progress for UI dashboard
  Map<String, int> get categoryTaskCounts {
    Map<String, int> counts = {};
    for (var todo in _todos) {
      counts[todo.category] = (counts[todo.category] ?? 0) + 1;
    }
    return counts;
  }

  // Category completed counts
  Map<String, int> get categoryCompletedCounts {
    Map<String, int> counts = {};
    for (var todo in _todos) {
      if (todo.isCompleted) {
        counts[todo.category] = (counts[todo.category] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  void dispose() {
    _todoSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}

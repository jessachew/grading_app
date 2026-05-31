import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_model.dart';

class TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if internet connection is available
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Stream of todos for a specific user
  Stream<List<TodoModel>> getTodosStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TodoModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Create a new task in Firestore
  Future<void> addTodo(String userId, TodoModel todo) async {
    try {
      final String id = todo.todoId.isEmpty
          ? _firestore.collection('users').doc(userId).collection('todos').doc().id
          : todo.todoId;
      
      final todoWithId = todo.copyWith(
        todoId: id,
        createdAt: todo.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(id)
          .set(todoWithId.toMap());
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  // Update an existing task
  Future<void> updateTodo(String userId, TodoModel todo) async {
    try {
      final todoWithUpdatedTime = todo.copyWith(
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(todo.todoId)
          .set(todoWithUpdatedTime.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete a task
  Future<void> deleteTodo(String userId, String todoId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(todoId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}

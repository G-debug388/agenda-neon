import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../utils/date_utils_br.dart';

/// Guarda as tarefas de um usuário agrupadas por dia ("2023-11-11").
///
/// É um [ChangeNotifier]: as telas escutam este objeto e se redesenham
/// sozinhas quando uma tarefa é adicionada, removida ou concluída.
/// A lista em memória é alterada de forma síncrona (a interface reage na
/// hora) e depois os dados são persistidos com shared_preferences.
class TaskRepository extends ChangeNotifier {
  TaskRepository(this.ownerEmail);

  final String ownerEmail;
  final Map<String, List<Task>> _byDay = {};
  bool _loaded = false;
  int _idSeed = 0;

  bool get isLoaded => _loaded;
  String get _storageKey => 'agenda_neon.tasks.$ownerEmail';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _byDay.clear();
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((day, list) {
        _byDay[day] = (list as List)
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    _byDay.removeWhere((_, list) => list.isEmpty);
    await prefs.setString(
      _storageKey,
      jsonEncode(
        _byDay.map(
          (day, list) => MapEntry(day, list.map((t) => t.toJson()).toList()),
        ),
      ),
    );
  }

  /// Tarefas do dia já ordenadas: pendentes (A-Z) e depois concluídas (A-Z).
  List<Task> tasksFor(DateTime day) =>
      Task.sortTasks(_byDay[dateKey(day)] ?? const []);

  ({int pending, int done}) countsFor(DateTime day) {
    final list = _byDay[dateKey(day)] ?? const <Task>[];
    final done = list.where((t) => t.done).length;
    return (pending: list.length - done, done: done);
  }

  ({int pending, int done}) countsForMonth(int year, int month) {
    var pending = 0;
    var done = 0;
    final prefix = '$year-${month.toString().padLeft(2, '0')}-';
    _byDay.forEach((day, list) {
      if (!day.startsWith(prefix)) return;
      for (final t in list) {
        t.done ? done++ : pending++;
      }
    });
    return (pending: pending, done: done);
  }

  /// Toda tarefa nova começa como NÃO concluída.
  Future<Task> add(DateTime day, String title) async {
    final clean = title.trim();
    if (clean.isEmpty) {
      throw ArgumentError('O nome da tarefa não pode ser vazio.');
    }
    final now = DateTime.now();
    final task = Task(
      id: '${now.microsecondsSinceEpoch}-${_idSeed++}',
      title: clean,
      createdAt: now,
    );
    _byDay.putIfAbsent(dateKey(day), () => []).add(task);
    notifyListeners();
    await _persist();
    return task;
  }

  Future<void> toggle(DateTime day, String id) async {
    final list = _byDay[dateKey(day)];
    if (list == null) return;
    final index = list.indexWhere((t) => t.id == id);
    if (index < 0) return;
    list[index] = list[index].copyWith(done: !list[index].done);
    notifyListeners();
    await _persist();
  }

  Future<Task?> remove(DateTime day, String id) async {
    final list = _byDay[dateKey(day)];
    if (list == null) return null;
    final index = list.indexWhere((t) => t.id == id);
    if (index < 0) return null;
    final removed = list.removeAt(index);
    notifyListeners();
    await _persist();
    return removed;
  }

  /// Usado pelo botão "Desfazer" depois de remover uma tarefa.
  Future<void> restore(DateTime day, Task task) async {
    final list = _byDay.putIfAbsent(dateKey(day), () => []);
    if (list.any((t) => t.id == task.id)) return;
    list.add(task);
    notifyListeners();
    await _persist();
  }
}

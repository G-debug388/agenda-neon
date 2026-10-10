import '../utils/date_utils_br.dart';

/// Uma tarefa diária. É imutável: alterações geram uma nova instância
/// através de [copyWith].
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.done = false,
  });

  final String id;
  final String title;
  final bool done;
  final DateTime createdAt;

  Task copyWith({String? title, bool? done}) => Task(
    id: id,
    title: title ?? this.title,
    done: done ?? this.done,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    done: json['done'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  /// Regra do enunciado: pendentes primeiro, depois as concluídas,
  /// e cada grupo em ordem alfabética (ignorando maiúsculas e acentos).
  static List<Task> sortTasks(Iterable<Task> tasks) {
    final list = List<Task>.of(tasks);
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final byName = normalizeForSort(a.title)
          .compareTo(normalizeForSort(b.title));
      if (byName != 0) return byName;
      final byRaw = a.title.compareTo(b.title);
      if (byRaw != 0) return byRaw;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }
}

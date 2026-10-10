import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_repository.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils_br.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/neon_background.dart';
import '../widgets/task_tile.dart';

/// Lista de tarefas de um dia. Pendentes primeiro, depois concluídas,
/// cada grupo em ordem alfabética (a ordenação fica no TaskRepository).
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.day, required this.repository});

  final DateTime day;
  final TaskRepository repository;

  Future<void> _addTask(BuildContext context) async {
    final title = await showAddTaskDialog(context, day);
    if (title == null || !context.mounted) return;
    await repository.add(day, title);
    if (!context.mounted) return;
    _snack(context, 'Tarefa "$title" adicionada!', Icons.add_task_rounded);
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    await repository.remove(day, task.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          duration: const Duration(seconds: 4),
          content: Text('"${task.title}" removida'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => repository.restore(day, task),
          ),
        ),
      );
  }

  void _snack(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              Icon(icon, color: AppColors.lime),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _AddButton(onPressed: () => _addTask(context)),
      body: NeonBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListenableBuilder(
                listenable: repository,
                builder: (context, _) {
                  final tasks = repository.tasksFor(day);
                  final pending = tasks.where((t) => !t.done).toList();
                  final done = tasks.where((t) => t.done).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(day: day, done: done.length, total: tasks.length),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(40),
                            ),
                          ),
                          child: tasks.isEmpty
                              ? const _EmptyState()
                              : ListView(
                                  key: const Key('task_list'),
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    24,
                                    18,
                                    120,
                                  ),
                                  children: [
                                    if (pending.isNotEmpty) ...[
                                      _SectionTitle(
                                        label: 'Pendentes',
                                        count: pending.length,
                                        color: AppColors.magenta,
                                      ),
                                      for (final t in pending)
                                        _tile(context, t),
                                    ],
                                    if (done.isNotEmpty) ...[
                                      if (pending.isNotEmpty)
                                        const SizedBox(height: 10),
                                      _SectionTitle(
                                        label: 'Concluídas',
                                        count: done.length,
                                        color: AppColors.mint,
                                      ),
                                      for (final t in done) _tile(context, t),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, Task task) => TaskTile(
    key: ValueKey(task.id),
    task: task,
    onToggle: () => repository.toggle(day, task.id),
    onDelete: () => _deleteTask(context, task),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.day, required this.done, required this.total});

  final DateTime day;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                child: IconButton(
                  key: const Key('btn_back'),
                  tooltip: 'Voltar ao calendário',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dia ${formatDate(day)}',
                      key: const Key('tasks_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      diasSemanaLongo[day.weekday % 7],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        total == 0
                            ? 'Dia livre por enquanto'
                            : '$done de $total concluída${total == 1 ? '' : 's'}',
                        key: const Key('progress_label'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.lime,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 12,
                    color: Colors.white.withValues(alpha: 0.2),
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      widthFactor: progress,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(gradient: AppColors.success),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
        child: Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mist,
              ),
              child: const Icon(
                Icons.wb_sunny_rounded,
                size: 56,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhuma tarefa por aqui',
              key: Key('empty_state'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toque no botão + para adicionar a primeira tarefa do dia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Adicionar tarefa',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.sunset,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.magenta.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          child: InkWell(
            key: const Key('fab_add'),
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const SizedBox(
              width: 68,
              height: 68,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 38),
            ),
          ),
        ),
      ),
    );
  }
}

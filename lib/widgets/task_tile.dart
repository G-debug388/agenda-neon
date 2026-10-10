import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// Um item da lista de tarefas.
/// * Tocar no círculo (ou no card) marca/desmarca como concluída.
/// * Lixeira ou arrastar para a esquerda remove a tarefa.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remover',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_rounded, color: Colors.white),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFEFFBF3) : AppColors.mist,
          borderRadius: BorderRadius.circular(22),
          border: Border(
            left: BorderSide(
              color: done ? AppColors.mint : AppColors.magenta,
              width: 6,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  Semantics(
                    label: done ? 'Desmarcar tarefa' : 'Marcar como concluída',
                    button: true,
                    child: GestureDetector(
                      key: const ValueKey('task_check'),
                      onTap: onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: done ? AppColors.success : null,
                          color: done ? null : Colors.white,
                          border: done
                              ? null
                              : Border.all(
                                  color: AppColors.magenta,
                                  width: 2.5,
                                ),
                        ),
                        child: done
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: done
                                ? AppColors.ink.withValues(alpha: 0.45)
                                : AppColors.ink,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.mint,
                            decorationThickness: 2,
                          ),
                          child: Text(task.title),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? AppColors.mint : AppColors.cyan,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              done ? 'Concluída' : 'Em andamento',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: done
                                    ? AppColors.mint
                                    : AppColors.violet.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('task_delete'),
                    tooltip: 'Remover tarefa',
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

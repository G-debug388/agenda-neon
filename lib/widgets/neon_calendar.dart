import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/date_utils_br.dart';

typedef DayCounts = ({int pending, int done}) Function(DateTime day);

/// Calendário mensal feito do zero (grade 6 x 7).
///
/// * Dia selecionado: círculo em degradê.
/// * Hoje: anel ciano.
/// * Pontinhos abaixo do número: magenta = tarefas pendentes,
///   verde = tarefas concluídas.
/// * Setas ou arrastar para os lados trocam o mês.
class NeonCalendar extends StatelessWidget {
  const NeonCalendar({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onMonthChanged,
    required this.countsFor,
    this.today,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;
  final DayCounts countsFor;
  final DateTime? today;

  void _changeMonth(int delta) =>
      onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + delta));

  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now();
    final first = DateTime(focusedMonth.year, focusedMonth.month);
    final offset = first.weekday % 7; // domingo = 0
    final days = List.generate(
      42,
      (i) => DateTime(first.year, first.month, 1 - offset + i),
    );

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() < 200) return;
        _changeMonth(v < 0 ? 1 : -1);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _NavButton(
                key: const Key('prev_month'),
                icon: Icons.chevron_left_rounded,
                tooltip: 'Mês anterior',
                onTap: () => _changeMonth(-1),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    '${mesesPt[focusedMonth.month - 1]} ${focusedMonth.year}',
                    key: ValueKey(focusedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              _NavButton(
                key: const Key('next_month'),
                icon: Icons.chevron_right_rounded,
                tooltip: 'Próximo mês',
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      diasSemanaCurto[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: i == 0 || i == 6
                            ? AppColors.magenta
                            : AppColors.violet.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var week = 0; week < 6; week++)
            Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: _DayCell(
                      day: days[week * 7 + d],
                      inMonth: days[week * 7 + d].month == focusedMonth.month,
                      selected: isSameDay(days[week * 7 + d], selectedDay),
                      isToday: isSameDay(days[week * 7 + d], now),
                      counts: countsFor(days[week * 7 + d]),
                      onTap: () => onDaySelected(days[week * 7 + d]),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.mist,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.violet, size: 26),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.counts,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final ({int pending, int done}) counts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? Colors.white
        : inMonth
        ? AppColors.ink
        : AppColors.ink.withValues(alpha: 0.25);

    return InkResponse(
      key: Key('day_${dateKey(day)}'),
      onTap: onTap,
      radius: 24,
      child: SizedBox(
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? AppColors.sunset : null,
                border: isToday && !selected
                    ? Border.all(color: AppColors.cyan, width: 2.5)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.magenta.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: selected || isToday
                      ? FontWeight.w900
                      : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (counts.pending > 0) _dot(AppColors.magenta),
                  if (counts.done > 0) _dot(AppColors.mint),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.symmetric(horizontal: 1.5),
    decoration: BoxDecoration(
      color: inMonth ? color : color.withValues(alpha: 0.3),
      shape: BoxShape.circle,
    ),
  );
}

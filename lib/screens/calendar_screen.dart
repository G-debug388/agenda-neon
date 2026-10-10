import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/task_repository.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils_br.dart';
import '../widgets/gradient_button.dart';
import '../widgets/neon_background.dart';
import '../widgets/neon_calendar.dart';
import 'auth_screen.dart';
import 'tasks_screen.dart';

/// Tela do calendário: o usuário escolhe um dia para ver/editar tarefas.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.user, this.today});

  final AppUser user;

  /// Permite fixar o "hoje" (útil em testes). Padrão: DateTime.now().
  final DateTime? today;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final TaskRepository _repository = TaskRepository(widget.user.email);
  late DateTime _today;
  late DateTime _selected;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _today = dateOnly(widget.today ?? DateTime.now());
    _selected = _today;
    _focusedMonth = DateTime(_today.year, _today.month);
    _repository.load();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selected = dateOnly(day);
      _focusedMonth = DateTime(day.year, day.month);
    });
  }

  void _goToToday() => _selectDay(_today);

  Future<void> _openSelectedDay() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) =>
            TasksScreen(day: _selected, repository: _repository),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text('Sair da conta?'),
        content: const Text('Suas tarefas continuam salvas neste aparelho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('btn_confirm_logout'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.magenta),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (leave != true) return;
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListenableBuilder(
                listenable: _repository,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildSheet()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final month = _repository.countsForMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${widget.user.firstName}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Escolha um dia e organize sua rotina.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                key: const Key('btn_profile'),
                tooltip: 'Perfil',
                offset: const Offset(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onSelected: (value) {
                  if (value == 'logout') _confirmLogout();
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      widget.user.email,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    key: Key('menu_logout'),
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.magenta),
                        SizedBox(width: 10),
                        Text('Sair'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.sunset,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Text(
                    widget.user.initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'RESUMO DE ${mesesPt[_focusedMonth.month - 1].toUpperCase()}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(
                icon: Icons.bolt_rounded,
                label: '${month.pending} pendentes',
                color: AppColors.orange,
              ),
              _StatChip(
                icon: Icons.check_circle_rounded,
                label: '${month.done} concluídas',
                color: AppColors.lime,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSheet() {
    final counts = _repository.countsFor(_selected);
    final total = counts.pending + counts.done;
    final isToday = isSameDay(_selected, _today);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
        children: [
          NeonCalendar(
            focusedMonth: _focusedMonth,
            selectedDay: _selected,
            today: _today,
            countsFor: _repository.countsFor,
            onDaySelected: _selectDay,
            onMonthChanged: (month) => setState(() => _focusedMonth = month),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 6,
            children: [
              _legend(AppColors.magenta, 'Pendentes'),
              _legend(AppColors.mint, 'Concluídas'),
              _legendRing('Hoje'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        diasSemanaCurto[_selected.weekday % 7].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_selected.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        longDate(_selected),
                        key: const Key('selected_day_label'),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total == 0
                            ? 'Nenhuma tarefa ainda'
                            : '${counts.pending} pendente${counts.pending == 1 ? '' : 's'}'
                                  ' · ${counts.done} concluída${counts.done == 1 ? '' : 's'}',
                        key: const Key('selected_day_counts'),
                        style: TextStyle(
                          color: AppColors.violet.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isToday)
                  TextButton(
                    key: const Key('btn_today'),
                    onPressed: _goToToday,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.magenta,
                    ),
                    child: const Text(
                      'Hoje',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GradientButton(
            key: const Key('btn_open_day'),
            label: 'Selecionar o dia',
            icon: Icons.arrow_forward_rounded,
            onPressed: _openSelectedDay,
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: _legendStyle),
    ],
  );

  Widget _legendRing(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cyan, width: 2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: _legendStyle),
    ],
  );

  TextStyle get _legendStyle => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.ink.withValues(alpha: 0.6),
  );
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

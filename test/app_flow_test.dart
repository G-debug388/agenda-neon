import 'package:agenda_neon/main.dart';
import 'package:agenda_neon/utils/date_utils_br.dart';
import 'package:agenda_neon/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.dragUntilVisible(
        finder, find.byType(ListView).first, const Offset(0, -150));
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

List<String> visibleTitles(WidgetTester tester) => tester
    .widgetList<TaskTile>(find.byType(TaskTile))
    .map((t) => '${t.task.title}${t.task.done ? ' ✓' : ''}')
    .toList();

Finder inTile(String title, String key) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(TaskTile)),
  matching: find.byKey(ValueKey(key)),
);

Future<void> addTask(WidgetTester tester, String title) async {
  await tapKey(tester, 'fab_add');
  expect(find.text('Nova tarefa'), findsOneWidget);
  await tester.enterText(find.byKey(const Key('field_task')), title);
  await tapKey(tester, 'btn_add_task');
  expect(find.text('Nova tarefa'), findsNothing);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Fluxo completo: cadastro, login, calendário e tarefas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AgendaNeonApp());
    await tester.pumpAndSettle();

    // ---------- CADASTRO ----------
    expect(find.text('Agenda Neon'), findsOneWidget);
    expect(find.byKey(const Key('field_name')), findsNothing);
    await tapKey(tester, 'tab_register');
    expect(find.byKey(const Key('field_name')), findsOneWidget);

    // Validações
    await tapKey(tester, 'btn_submit');
    expect(find.text('Informe seu nome'), findsOneWidget);
    expect(find.text('E-mail inválido'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('field_name')), 'Mateus Souza');
    await tester.enterText(
      find.byKey(const Key('field_email')),
      'mateus@email.com',
    );
    await tester.enterText(find.byKey(const Key('field_password')), '123456');
    await tester.enterText(find.byKey(const Key('field_confirm')), '999999');
    await tapKey(tester, 'btn_submit');
    expect(find.text('As senhas não conferem'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('field_confirm')), '123456');
    await tapKey(tester, 'btn_submit');
    expect(find.textContaining('Conta criada com sucesso'), findsOneWidget);
    // Voltou para o modo login com o e-mail preenchido
    expect(find.byKey(const Key('field_name')), findsNothing);
    expect(find.text('mateus@email.com'), findsOneWidget);

    // E-mail duplicado
    await tapKey(tester, 'tab_register');
    await tester.enterText(find.byKey(const Key('field_password')), '123456');
    await tester.enterText(find.byKey(const Key('field_confirm')), '123456');
    await tapKey(tester, 'btn_submit');
    expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
    await tapKey(tester, 'tab_login');

    // ---------- LOGIN ----------
    await tester.enterText(find.byKey(const Key('field_password')), 'errada');
    await tapKey(tester, 'btn_submit');
    expect(find.text('Senha incorreta. Tente novamente.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('field_password')), '123456');
    await tapKey(tester, 'btn_submit');

    // ---------- CALENDÁRIO ----------
    expect(find.text('Olá, Mateus!'), findsOneWidget);
    final now = DateTime.now();
    final monthLabel = '${mesesPt[now.month - 1]} ${now.year}';
    expect(find.text(monthLabel), findsOneWidget);
    expect(find.byKey(const Key('btn_today')), findsNothing);

    await tapKey(tester, 'next_month');
    final next = DateTime(now.year, now.month + 1);
    expect(
      find.text('${mesesPt[next.month - 1]} ${next.year}'),
      findsOneWidget,
    );
    await tapKey(tester, 'prev_month');
    expect(find.text(monthLabel), findsOneWidget);

    final day = DateTime(now.year, now.month, now.day == 15 ? 16 : 15);
    await tapKey(tester, 'day_${dateKey(day)}');
    expect(find.text(longDate(day)), findsOneWidget);
    expect(find.byKey(const Key('btn_today')), findsOneWidget);
    expect(find.text('Nenhuma tarefa ainda'), findsOneWidget);

    await tapKey(tester, 'btn_open_day');

    // ---------- LISTA DE TAREFAS ----------
    expect(find.text('Dia ${formatDate(day)}'), findsOneWidget);
    expect(find.byKey(const Key('empty_state')), findsOneWidget);

    // Diálogo: não aceita vazio e pode ser cancelado
    await tapKey(tester, 'fab_add');
    await tapKey(tester, 'btn_add_task');
    expect(find.text('Digite um nome para a tarefa'), findsOneWidget);
    await tapKey(tester, 'btn_cancel_task');
    expect(find.text('Nova tarefa'), findsNothing);
    expect(find.byType(TaskTile), findsNothing);

    await addTask(tester, 'Zumba');
    await addTask(tester, 'arrumar quarto');
    await addTask(tester, 'Estudar Flutter');
    await addTask(tester, 'Água nas plantas');

    // Todas começam pendentes e em ordem alfabética
    expect(visibleTitles(tester), [
      'Água nas plantas',
      'arrumar quarto',
      'Estudar Flutter',
      'Zumba',
    ]);
    expect(find.text('0 de 4 concluídas'), findsOneWidget);

    // Marcar como concluída -> vai para o grupo de concluídas
    await tester.tap(inTile('Zumba', 'task_check'));
    await tester.pumpAndSettle();
    await tester.tap(inTile('arrumar quarto', 'task_check'));
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), [
      'Água nas plantas',
      'Estudar Flutter',
      'arrumar quarto ✓',
      'Zumba ✓',
    ]);
    expect(find.text('2 de 4 concluídas'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    // Desmarcar (tocando no card) -> volta para pendentes
    await tester.tap(find.text('Zumba'));
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), [
      'Água nas plantas',
      'Estudar Flutter',
      'Zumba',
      'arrumar quarto ✓',
    ]);

    // Remover pela lixeira + desfazer
    await tester.tap(inTile('Zumba', 'task_delete'));
    await tester.pumpAndSettle();
    expect(find.text('Zumba'), findsNothing);
    expect(find.text('"Zumba" removida'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(find.text('Zumba'), findsOneWidget);

    // Remover arrastando para a esquerda
    await tester.drag(
      find.ancestor(
        of: find.text('Estudar Flutter'),
        matching: find.byType(Dismissible),
      ),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), [
      'Água nas plantas',
      'Zumba',
      'arrumar quarto ✓',
    ]);
    expect(find.text('1 de 3 concluídas'), findsOneWidget);

    // ---------- VOLTA AO CALENDÁRIO ----------
    await tapKey(tester, 'btn_back');
    expect(find.text('2 pendentes · 1 concluída'), findsOneWidget);

    // ---------- LOGOUT ----------
    await tapKey(tester, 'btn_profile');
    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();
    await tapKey(tester, 'btn_confirm_logout');
    expect(find.text('Agenda Neon'), findsOneWidget);

    // ---------- LOGIN DE NOVO: dados continuam salvos ----------
    await tester.enterText(
      find.byKey(const Key('field_email')),
      'mateus@email.com',
    );
    await tester.enterText(find.byKey(const Key('field_password')), '123456');
    await tapKey(tester, 'btn_submit');
    await tapKey(tester, 'day_${dateKey(day)}');
    expect(find.text('2 pendentes · 1 concluída'), findsOneWidget);
    await tapKey(tester, 'btn_open_day');
    expect(visibleTitles(tester), [
      'Água nas plantas',
      'Zumba',
      'arrumar quarto ✓',
    ]);

    // Deixa os SnackBars terminarem
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Sessão salva abre direto no calendário', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'agenda_neon.users': '{"ana@x.com":{"name":"Ana Lima","email":"ana@x.com","passwordHash":"x"}}',
      'agenda_neon.session': 'ana@x.com',
    });
    await tester.pumpWidget(const AgendaNeonApp());
    await tester.pumpAndSettle();
    expect(find.text('Olá, Ana!'), findsOneWidget);
  });

  testWidgets('Layout não estoura em tela pequena (320x568)', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'agenda_neon.users': '{"ana@x.com":{"name":"Ana Lima","email":"ana@x.com","passwordHash":"x"}}',
      'agenda_neon.session': 'ana@x.com',
    });
    await tester.pumpWidget(const AgendaNeonApp());
    await tester.pumpAndSettle();
    await tapKey(tester, 'btn_open_day');
    await addTask(
      tester,
      'Uma tarefa com um nome bem comprido para testar o layout',
    );
    await tapKey(tester, 'fab_add');
    expect(tester.takeException(), isNull);
  });
}

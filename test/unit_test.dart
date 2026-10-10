import 'package:agenda_neon/models/task.dart';
import 'package:agenda_neon/services/auth_service.dart';
import 'package:agenda_neon/services/task_repository.dart';
import 'package:agenda_neon/utils/date_utils_br.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Task _t(String title, {bool done = false}) =>
    Task(id: title, title: title, done: done, createdAt: DateTime(2023));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Ordenação das tarefas', () {
    test(
      'pendentes primeiro, depois concluídas, ambas em ordem alfabética',
      () {
        final sorted = Task.sortTasks([
          _t('Zebra', done: true),
          _t('caderno'),
          _t('Banana'),
          _t('Abacate', done: true),
          _t('Água'),
          _t('maçã', done: true),
        ]);
        expect(sorted.map((t) => t.title).toList(), [
          'Água',
          'Banana',
          'caderno',
          'Abacate',
          'maçã',
          'Zebra',
        ]);
      },
    );

    test('normalizeForSort remove acentos e maiúsculas', () {
      expect(normalizeForSort('  Ação Única '), 'acao unica');
    });
  });

  group('Datas', () {
    test('formatos em português', () {
      final d = DateTime(2023, 11, 11);
      expect(formatDate(d), '11/11/2023');
      expect(dateKey(d), '2023-11-11');
      expect(longDate(d), 'Sábado, 11 de novembro de 2023');
    });
  });

  group('AuthService', () {
    test('cadastro, login, sessão e logout', () async {
      final auth = AuthService();
      await auth.register(
        name: 'Mateus Silva',
        email: 'Mateus@Email.com',
        password: '123456',
      );

      expect(await auth.currentUser(), isNull);
      final user = await auth.login(' mateus@email.com ', '123456');
      expect(user.firstName, 'Mateus');
      expect((await auth.currentUser())?.email, 'mateus@email.com');

      await auth.logout();
      expect(await auth.currentUser(), isNull);
    });

    test('a senha não é salva em texto puro', () async {
      await AuthService().register(
        name: 'Ana',
        email: 'ana@x.com',
        password: 'segredo1',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('agenda_neon.users'), isNot(contains('segredo1')));
    });

    test('erros: e-mail duplicado, senha errada, conta inexistente', () async {
      final auth = AuthService();
      await auth.register(name: 'Ana', email: 'ana@x.com', password: '123456');
      expect(
        () => auth.register(
          name: 'Ana 2',
          email: 'ANA@x.com',
          password: '654321',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => auth.login('ana@x.com', 'errada'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => auth.login('nao@existe.com', '123456'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => auth.register(name: 'B', email: 'invalido', password: '123456'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => auth.register(name: 'Bia', email: 'b@b.com', password: '123'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('TaskRepository', () {
    final day = DateTime(2023, 11, 11);

    test(
      'adicionar começa como não concluída; marcar; remover; desfazer',
      () async {
        final repo = TaskRepository('a@a.com');
        await repo.load();

        final t = await repo.add(day, '  Estudar  ');
        expect(t.title, 'Estudar');
        expect(t.done, isFalse);

        await repo.add(day, 'Academia');
        await repo.toggle(day, t.id);
        expect(repo.tasksFor(day).map((e) => '${e.title}:${e.done}'), [
          'Academia:false',
          'Estudar:true',
        ]);
        expect(repo.countsFor(day), (pending: 1, done: 1));
        expect(repo.countsForMonth(2023, 11), (pending: 1, done: 1));

        final removed = await repo.remove(day, t.id);
        expect(repo.tasksFor(day).length, 1);
        await repo.restore(day, removed!);
        expect(repo.tasksFor(day).length, 2);

        expect(() => repo.add(day, '   '), throwsArgumentError);
      },
    );

    test('dados persistem e são separados por usuário e por dia', () async {
      final repo = TaskRepository('a@a.com');
      await repo.load();
      await repo.add(day, 'Tarefa A');
      await repo.add(DateTime(2023, 11, 12), 'Outro dia');

      final reloaded = TaskRepository('a@a.com');
      await reloaded.load();
      expect(reloaded.tasksFor(day).single.title, 'Tarefa A');
      expect(
        reloaded.tasksFor(DateTime(2023, 11, 12)).single.title,
        'Outro dia',
      );

      final other = TaskRepository('b@b.com');
      await other.load();
      expect(other.tasksFor(day), isEmpty);
    });
  });
}

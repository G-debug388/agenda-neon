import 'package:agenda_neon/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App abre na tela de login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AgendaNeonApp());
    await tester.pumpAndSettle();

    expect(find.text('Agenda Neon'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Cadastrar'), findsOneWidget);
  });
}

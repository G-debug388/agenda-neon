/// Funções utilitárias de data em português (sem depender de pacotes de
/// internacionalização) e de normalização de texto para ordenação.
library;

const List<String> mesesPt = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Índice 0 = domingo (use `weekday % 7`).
const List<String> diasSemanaCurto = [
  'Dom',
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
];

const List<String> diasSemanaLongo = [
  'Domingo',
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// 11/11/2023
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// Chave usada para guardar as tarefas de um dia: 2023-11-11
String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// Sábado, 11 de novembro de 2023
String longDate(DateTime d) =>
    '${diasSemanaLongo[d.weekday % 7]}, ${d.day} de '
    '${mesesPt[d.month - 1].toLowerCase()} de ${d.year}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const String _accented = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
const String _plain =
    'aaaaaa'
    'c'
    'eeee'
    'iiii'
    'n'
    'ooooo'
    'uuuu'
    'yy';

/// Deixa o texto em minúsculas e sem acentos para que a ordem alfabética
/// fique correta em português ("Água" vem antes de "Banana").
String normalizeForSort(String text) {
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = _accented.indexOf(char);
    buffer.write(index >= 0 ? _plain[index] : char);
  }
  return buffer.toString();
}

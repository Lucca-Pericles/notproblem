import 'package:agile_knowledge/app/agile_knowledge_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe o dashboard inicial', (tester) async {
    await tester.pumpWidget(const AgileKnowledgeApp());

    expect(find.text('Olá, Gustavo'), findsOneWidget);
    expect(find.text('Registrar atraso'), findsOneWidget);
  });
}

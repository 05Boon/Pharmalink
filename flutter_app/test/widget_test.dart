import 'package:flutter_test/flutter_test.dart';

import 'package:pharmacy_network/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PharmacyNetworkApp());
    await tester.pump();

    expect(find.text('Sign in to your account'), findsOneWidget);
  });
}

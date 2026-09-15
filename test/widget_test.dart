import 'package:dermaire_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('welcome supports dark mode and opens create account', (
    tester,
  ) async {
    await tester.pumpWidget(const DermaireApp());
    await tester.pumpAndSettle();

    expect(find.text('Dermaire'), findsOneWidget);
    expect(find.text('Start my skin experiment'), findsOneWidget);

    await tester.tap(find.byKey(const Key('themeToggle')));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    await tester.tap(find.byKey(const Key('startExperimentButton')));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
    expect(find.text('Sign up with Google'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('account creation validates fields and gates safety acceptance', (
    tester,
  ) async {
    await tester.pumpWidget(const DermaireApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('startExperimentButton')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createAccountButton')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(
      find.text('Use 8+ characters with upper, lower and a number'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('createEmail')),
      'salma@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('createPassword')),
      'HealthySkin9!',
    );
    await tester.enterText(
      find.byKey(const Key('confirmPassword')),
      'HealthySkin9!',
    );
    await tester.tap(find.byKey(const Key('createAccountButton')));
    await tester.pumpAndSettle();

    expect(find.text('Safety & responsibility'), findsOneWidget);
    final continueButton = tester.widget<FilledButton>(
      find.byKey(const Key('acceptSafetyButton')),
    );
    expect(continueButton.onPressed, isNull);

    await tester.drag(
      find.byKey(const Key('safetyScroll')),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    final enabledButton = tester.widget<FilledButton>(
      find.byKey(const Key('acceptSafetyButton')),
    );
    expect(enabledButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('acceptSafetyButton')));
    await tester.pumpAndSettle();
    expect(find.text('Account created'), findsOneWidget);

    await tester.tap(find.text('Start my skin experiment'));
    await tester.pumpAndSettle();
    expect(find.text('Tell us about your skin'), findsOneWidget);
    for (final concern in [
      'Acne',
      'Redness',
      'Texture',
      'Dryness',
      'Oiliness',
      'Other',
    ]) {
      expect(find.text(concern), findsOneWidget);
    }
  });

  testWidgets('sign in, forgot password, and app navigation work', (
    tester,
  ) async {
    await tester.pumpWidget(const DermaireApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('existingAccountButton')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('resetEmail')),
      'salma@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    expect(find.textContaining('Reset link sent'), findsOneWidget);
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('signInEmail')),
      'salma@example.com',
    );
    await tester.enterText(find.byKey(const Key('signInPassword')), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('of 28'), findsOneWidget);

    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(find.text('Current routine'), findsOneWidget);
  });
}

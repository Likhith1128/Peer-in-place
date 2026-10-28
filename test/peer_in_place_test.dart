import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peer_in_place/app_state.dart';
import 'package:peer_in_place/main.dart';

void main() {
  test('morning survey is once a day and a high-risk visit alerts the peer', () {
    final state = AppState(clock: () => DateTime(2026, 6, 14, 10));
    expect(state.signIn('jordan@peerinplace.app', 'peerplace'), isTrue);
    final summary = state.summaryFor('user-jordan');
    expect(summary.dailyCount, 6);
    expect(summary.useDays, 3);
    expect(summary.locationCount, 1);
    expect(state.placesFor('user-jordan'), hasLength(5));

    final before = state.alertsFor('peer-morgan').length;
    state.recordLocationVisit(
      participantId: 'user-jordan',
      placeId: 'place-bar',
      present: true,
      mood: 'Low',
      intent: 'Moderate',
      context: 'Alone',
    );
    expect(state.alertsFor('peer-morgan').length, before + 1);

    expect(
      state.recordDaily(
        participantId: 'user-jordan',
        mood: 'Okay',
        use: 'No',
        context: 'Home',
        goal: 'Yes',
      ),
      isTrue,
    );
    expect(
      state.recordDaily(
        participantId: 'user-jordan',
        mood: 'Okay',
        use: 'No',
        context: 'Home',
        goal: 'Yes',
      ),
      isFalse,
    );
    expect(state.addPlace(
      participantId: 'user-jordan',
      name: 'Sixth place',
      kind: state.placeById('place-bar')!.kind,
      note: 'too many',
    ), 'Each participant can flag up to 5 places.');
  });

  test('verification code chooses the role', () {
    final state = AppState(clock: () => DateTime(2026, 6, 14, 10));
    expect(
      state.beginSignUp('new.person@peerinplace.app', 'peerplace', 'peerplace'),
      isNull,
    );
    expect(state.verify('PIP-PEER'), isNull);
    expect(state.currentUser?.role.name, 'peer');
    expect(state.signIn('alex@peerinplace.app', 'wrong-password'), isFalse);
  });

  testWidgets('participant can finish the morning survey', (tester) async {
    await tester.pumpWidget(const PeerInPlaceApp());
    await tester.ensureVisible(find.byKey(const Key('demo-participant')));
    await tester.tap(find.byKey(const Key('demo-participant')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('take-daily')));
    await tester.tap(find.byKey(const Key('take-daily')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('survey-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('answer-Okay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('survey-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('answer-No')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('survey-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('answer-Home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('survey-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('answer-Yes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('survey-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('survey-done')), findsOneWidget);
    expect(find.text('Great job'), findsOneWidget);
  });

  testWidgets('admin directory lists participants', (tester) async {
    await tester.pumpWidget(const PeerInPlaceApp());
    await tester.ensureVisible(find.byKey(const Key('demo-admin')));
    await tester.tap(find.byKey(const Key('demo-admin')));
    await tester.pumpAndSettle();
    expect(find.text('Admin portal'), findsWidgets);
    await tester.tap(find.text('Participants').first);
    await tester.pumpAndSettle();
    expect(find.text('Jordan Lee'), findsOneWidget);
  });
}

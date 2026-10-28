import 'package:flutter/foundation.dart';

import 'content.dart';
import 'format.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _seed();
  }

  final DateTime Function() _clock;
  DateTime get now => _clock();

  final List<AppUser> users = [];
  final List<Place> places = [];
  final List<SurveyRecord> surveys = [];
  final List<ChatMessage> messages = [];
  final List<PeerAlert> alerts = [];
  final List<CalendarEvent> events = [];
  final List<ContactNote> contacts = [];
  final Map<String, String> goals = {};
  final Map<String, Set<String>> savedArticles = {};

  AppUser? currentUser;
  PendingSignup? pending;
  int _n = 100;

  String _nextId(String prefix) => '$prefix-${_n++}';

  List<AppUser> get participants =>
      users.where((user) => user.role == UserRole.participant).toList();

  List<AppUser> get peers =>
      users.where((user) => user.role == UserRole.peer).toList();

  AppUser? userById(String id) {
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  Place? placeById(String id) {
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  List<Place> placesFor(String participantId) =>
      places.where((place) => place.participantId == participantId).toList();

  List<SurveyRecord> surveysFor(String participantId) {
    final rows = surveys
        .where((survey) => survey.participantId == participantId)
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return rows;
  }

  List<ChatMessage> threadFor(String participantId) {
    final rows = messages
        .where((message) => message.participantId == participantId)
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    return rows;
  }

  List<CalendarEvent> eventsFor(String participantId) {
    final rows = events
        .where((event) => event.participantId == participantId)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return rows;
  }

  List<PeerAlert> alertsFor(String peerId) {
    final rows = alerts.where((alert) => alert.peerId == peerId).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return rows;
  }

  String goalFor(String userId) =>
      goals[userId] ?? 'Take one step that makes use less likely today.';

  bool isSaved(String userId, String articleId) =>
      savedArticles[userId]?.contains(articleId) ?? false;

  bool completedDailyOn(String participantId, [DateTime? day]) {
    final target = dateOnly(day ?? now);
    return surveys.any(
      (survey) =>
          survey.participantId == participantId &&
          survey.kind == SurveyKind.daily &&
          sameDay(survey.at, target),
    );
  }

  WeekSummary summaryFor(String participantId) {
    final recent = surveys.where(
      (survey) =>
          survey.participantId == participantId && inLast7Days(survey.at, now),
    );
    final useDays = <DateTime>{};
    var dailyCount = 0;
    var locationCount = 0;
    for (final survey in recent) {
      if (survey.kind == SurveyKind.daily) {
        dailyCount += 1;
        if (reportedUse(survey.use)) useDays.add(dateOnly(survey.at));
      } else if (survey.kind == SurveyKind.location && survey.present == true) {
        locationCount += 1;
      }
    }
    return WeekSummary(
      dailyCount: dailyCount,
      useDays: useDays.length,
      locationCount: locationCount,
    );
  }

  List<int> activeSeries(UserRole role) {
    final points = <int>[];
    for (var week = 7; week >= 0; week--) {
      final end = dateOnly(now).subtract(Duration(days: week * 7));
      points.add(
        users
            .where(
              (user) =>
                  user.role == role &&
                  user.active &&
                  !dateOnly(user.createdAt).isAfter(end),
            )
            .length,
      );
    }
    return points;
  }

  List<double> moodSeries(String participantId) {
    final rows = surveys
        .where(
          (survey) =>
              survey.participantId == participantId &&
              moodScore(survey.mood) > 0,
        )
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final recent = rows.length > 14 ? rows.sublist(rows.length - 14) : rows;
    return recent.map((survey) => moodScore(survey.mood).toDouble()).toList();
  }

  List<double> useSeries(String participantId) {
    final dailies = surveys
        .where(
          (survey) =>
              survey.participantId == participantId &&
              survey.kind == SurveyKind.daily,
        )
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final recent =
        dailies.length > 14 ? dailies.sublist(dailies.length - 14) : dailies;
    return recent
        .map((survey) => reportedUse(survey.use) ? 1.0 : 0.0)
        .toList();
  }

  bool signIn(String email, String password) {
    final match = _byEmail(email);
    if (match == null || match.password != password || !match.active) {
      return false;
    }
    currentUser = match;
    pending = null;
    notifyListeners();
    return true;
  }

  String? beginSignUp(String email, String password, String confirm) {
    final trimmed = email.trim().toLowerCase();
    if (!_validEmail(trimmed)) return 'Enter a valid email address.';
    if (password.length < 8) return 'Use at least 8 characters.';
    if (password != confirm) return 'Passwords do not match.';
    if (_byEmail(trimmed) != null) {
      return 'An account with that email already exists.';
    }
    pending = PendingSignup(
      name: _nameFromEmail(trimmed),
      email: trimmed,
      password: password,
    );
    notifyListeners();
    return null;
  }

  String? verify(String code) {
    final signup = pending;
    if (signup == null) return 'Start from Create account.';
    final role = switch (code.trim().toUpperCase()) {
      participantCode => UserRole.participant,
      peerCode => UserRole.peer,
      adminCode => UserRole.admin,
      _ => null,
    };
    if (role == null) return 'That verification code is not recognized.';
    final user = AppUser(
      id: _nextId(role.name),
      name: signup.name,
      email: signup.email,
      password: signup.password,
      role: role,
      active: true,
      createdAt: now,
    );
    users.add(user);
    goals[user.id] = 'Take one step that makes use less likely today.';
    currentUser = user;
    pending = null;
    notifyListeners();
    return null;
  }

  void cancelPending() {
    pending = null;
    notifyListeners();
  }

  void signOut() {
    currentUser = null;
    notifyListeners();
  }

  String? resetPassword(String email) {
    final match = _byEmail(email);
    if (match == null) return 'No account uses that email.';
    match.password = demoPassword;
    notifyListeners();
    return null;
  }

  bool recordDaily({
    required String participantId,
    required String mood,
    required String use,
    required String context,
    required String goal,
  }) {
    if (completedDailyOn(participantId)) return false;
    surveys.add(
      SurveyRecord(
        id: _nextId('survey'),
        participantId: participantId,
        kind: SurveyKind.daily,
        at: now,
        mood: mood,
        use: use,
        context: context,
        goal: goal,
      ),
    );
    notifyListeners();
    return true;
  }

  void recordLocationVisit({
    required String participantId,
    required String placeId,
    required bool present,
    String? mood,
    String? intent,
    String? context,
  }) {
    final place = placeById(placeId);
    final participant = userById(participantId);
    surveys.add(
      SurveyRecord(
        id: _nextId('survey'),
        participantId: participantId,
        kind: SurveyKind.location,
        at: now,
        mood: mood,
        intent: intent,
        context: context,
        present: present,
        placeId: placeId,
      ),
    );
    if (present &&
        place != null &&
        place.isHighRisk &&
        participant?.peerId != null) {
      alerts.add(
        PeerAlert(
          id: _nextId('alert'),
          peerId: participant!.peerId!,
          participantId: participantId,
          placeName: place.name,
          at: now,
        ),
      );
    }
    notifyListeners();
  }

  void recordHealthyVisit({
    required String participantId,
    required String placeId,
    required String mood,
  }) {
    surveys.add(
      SurveyRecord(
        id: _nextId('survey'),
        participantId: participantId,
        kind: SurveyKind.healthy,
        at: now,
        mood: mood,
        present: true,
        placeId: placeId,
      ),
    );
    notifyListeners();
  }

  String? addPlace({
    required String participantId,
    required String name,
    required PlaceKind kind,
    required String note,
    double? latitude,
    double? longitude,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Name the place.';
    if (placesFor(participantId).length >= 5) {
      return 'Each participant can flag up to 5 places.';
    }
    places.add(
      Place(
        id: _nextId('place'),
        participantId: participantId,
        name: trimmed,
        kind: kind,
        note: note.trim().isEmpty
            ? (kind == PlaceKind.highRisk
                ? 'Text your peer if the urge shows up here.'
                : 'You chose this as a supportive place.')
            : note.trim(),
        latitude: latitude,
        longitude: longitude,
      ),
    );
    notifyListeners();
    return null;
  }

  void removePlace(String placeId) {
    places.removeWhere((place) => place.id == placeId);
    notifyListeners();
  }

  void sendMessage({
    required String participantId,
    required String peerId,
    required String senderId,
    required UserRole senderRole,
    required String body,
    String? header,
    DateTime? scheduledFor,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    messages.add(
      ChatMessage(
        id: _nextId('msg'),
        participantId: participantId,
        peerId: peerId,
        senderId: senderId,
        senderRole: senderRole,
        body: trimmed,
        header: header?.trim().isEmpty ?? true ? null : header!.trim(),
        at: now,
        scheduledFor: scheduledFor,
      ),
    );
    notifyListeners();
  }

  void addEvent({
    required String participantId,
    required String title,
    required DateTime start,
    required String location,
    required String notes,
    required String createdBy,
  }) {
    if (title.trim().isEmpty) return;
    events.add(
      CalendarEvent(
        id: _nextId('event'),
        participantId: participantId,
        title: title.trim(),
        start: start,
        location: location.trim(),
        notes: notes.trim(),
        createdBy: createdBy,
      ),
    );
    notifyListeners();
  }

  void deleteEvent(String eventId) {
    events.removeWhere((event) => event.id == eventId);
    notifyListeners();
  }

  void assignPeer(String participantId, String? peerId) {
    final user = userById(participantId);
    if (user == null) return;
    user.peerId = peerId;
    notifyListeners();
  }

  void setRole(String userId, UserRole role) {
    final user = userById(userId);
    if (user == null) return;
    user.role = role;
    if (role != UserRole.participant) user.peerId = null;
    notifyListeners();
  }

  void setActive(String userId, bool active) {
    final user = userById(userId);
    if (user == null) return;
    user.active = active;
    notifyListeners();
  }

  String? deleteUser(String userId) {
    if (currentUser?.id == userId) {
      return 'Sign in as someone else before deleting this account.';
    }
    users.removeWhere((user) => user.id == userId);
    places.removeWhere((place) => place.participantId == userId);
    surveys.removeWhere((survey) => survey.participantId == userId);
    messages.removeWhere(
      (message) =>
          message.participantId == userId || message.senderId == userId,
    );
    alerts.removeWhere(
      (alert) => alert.participantId == userId || alert.peerId == userId,
    );
    events.removeWhere((event) => event.participantId == userId);
    goals.remove(userId);
    savedArticles.remove(userId);
    notifyListeners();
    return null;
  }

  void setGoal(String userId, String goal) {
    final trimmed = goal.trim();
    if (trimmed.isEmpty) return;
    goals[userId] = trimmed;
    notifyListeners();
  }

  void toggleSaved(String userId, String articleId) {
    final saved = savedArticles.putIfAbsent(userId, () => <String>{});
    if (!saved.add(articleId)) saved.remove(articleId);
    notifyListeners();
  }

  void sendContact({
    required String fromEmail,
    required String subject,
    required String body,
  }) {
    if (subject.trim().isEmpty || body.trim().isEmpty) return;
    contacts.add(
      ContactNote(
        id: _nextId('contact'),
        fromEmail: fromEmail,
        subject: subject.trim(),
        body: body.trim(),
        at: now,
      ),
    );
    notifyListeners();
  }

  void markAlertRead(String alertId) {
    for (final alert in alerts) {
      if (alert.id == alertId) alert.read = true;
    }
    notifyListeners();
  }

  String exportCsv() {
    final lines = <String>[
      'record_type,id,name,email,role,status,created,detail',
    ];
    for (final user in users) {
      final peer = user.peerId == null ? '' : userById(user.peerId!)?.name ?? '';
      lines.add(
        [
          'user',
          user.id,
          user.name,
          user.email,
          user.role.name,
          user.active ? 'active' : 'inactive',
          shortDate(user.createdAt),
          peer,
        ].map(csvField).join(','),
      );
    }
    for (final survey in surveys) {
      final place = survey.placeId == null ? '' : placeById(survey.placeId!)?.name ?? '';
      lines.add(
        [
          survey.kind.name,
          survey.id,
          userById(survey.participantId)?.name ?? survey.participantId,
          '',
          '',
          survey.present == null ? '' : (survey.present! ? 'present' : 'not present'),
          shortDate(survey.at),
          [survey.mood, survey.use, survey.intent, survey.context, place]
              .whereType<String>()
              .where((part) => part.isNotEmpty)
              .join(' | '),
        ].map(csvField).join(','),
      );
    }
    return '${lines.join('\n')}\n';
  }

  AppUser? _byEmail(String email) {
    final trimmed = email.trim().toLowerCase();
    for (final user in users) {
      if (user.email == trimmed) return user;
    }
    return null;
  }

  bool _validEmail(String email) {
    final at = email.indexOf('@');
    return at > 0 && email.indexOf('.', at) > at + 1 && !email.endsWith('.');
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
    return local
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _seed() {
    users.addAll([
      AppUser(
        id: 'admin-alex',
        name: 'Alex Morgan',
        email: 'alex@peerinplace.app',
        password: demoPassword,
        role: UserRole.admin,
        active: true,
        createdAt: now.subtract(const Duration(days: 80)),
      ),
      AppUser(
        id: 'peer-morgan',
        name: 'Morgan Blake',
        email: 'morgan@peerinplace.app',
        password: demoPassword,
        role: UserRole.peer,
        active: true,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      AppUser(
        id: 'peer-quinn',
        name: 'Quinn Adams',
        email: 'quinn@peerinplace.app',
        password: demoPassword,
        role: UserRole.peer,
        active: true,
        createdAt: now.subtract(const Duration(days: 24)),
      ),
      AppUser(
        id: 'user-jordan',
        name: 'Jordan Lee',
        email: 'jordan@peerinplace.app',
        password: demoPassword,
        role: UserRole.participant,
        active: true,
        createdAt: now.subtract(const Duration(days: 70)),
        peerId: 'peer-morgan',
      ),
      AppUser(
        id: 'user-sam',
        name: 'Sam Ortiz',
        email: 'sam@peerinplace.app',
        password: demoPassword,
        role: UserRole.participant,
        active: true,
        createdAt: now.subtract(const Duration(days: 50)),
        peerId: 'peer-morgan',
      ),
      AppUser(
        id: 'user-riley',
        name: 'Riley Chen',
        email: 'riley@peerinplace.app',
        password: demoPassword,
        role: UserRole.participant,
        active: true,
        createdAt: now.subtract(const Duration(days: 32)),
        peerId: 'peer-quinn',
      ),
      AppUser(
        id: 'user-avery',
        name: 'Avery Patel',
        email: 'avery@peerinplace.app',
        password: demoPassword,
        role: UserRole.participant,
        active: false,
        createdAt: now.subtract(const Duration(days: 20)),
        peerId: 'peer-quinn',
      ),
      AppUser(
        id: 'user-casey',
        name: 'Casey Nguyen',
        email: 'casey@peerinplace.app',
        password: demoPassword,
        role: UserRole.participant,
        active: true,
        createdAt: now.subtract(const Duration(days: 10)),
        peerId: 'peer-morgan',
      ),
      AppUser(
        id: 'user-drew',
        name: 'Drew Alvarez',
        email: 'drew@peerinplace.app',
        password: demoPassword,
        role: UserRole.participant,
        active: true,
        createdAt: now.subtract(const Duration(days: 2)),
        peerId: 'peer-quinn',
      ),
    ]);

    places.addAll([
      Place(
        id: 'place-bar',
        participantId: 'user-jordan',
        name: 'Main Street Bar',
        kind: PlaceKind.highRisk,
        note:
            'You planned to leave Main Street if the urge showed up. Text me and walk toward the park.',
      ),
      Place(
        id: 'place-park',
        participantId: 'user-jordan',
        name: 'Riverside Park',
        kind: PlaceKind.healthy,
        note: 'You made it to Riverside Park. That is one of your supportive places.',
      ),
      Place(
        id: 'place-stop',
        participantId: 'user-jordan',
        name: 'Night bus stop',
        kind: PlaceKind.highRisk,
        note:
            'The night bus stop is a cue. Step inside the store or call me before you decide.',
      ),
      Place(
        id: 'place-clinic',
        participantId: 'user-jordan',
        name: 'Clinic lobby',
        kind: PlaceKind.healthy,
        note: 'The clinic is a place you chose on purpose. Notice your mood before you leave.',
      ),
      Place(
        id: 'place-kitchen',
        participantId: 'user-jordan',
        name: "Cousin's kitchen",
        kind: PlaceKind.highRisk,
        note:
            'You asked for a check-in in this kitchen. Rate the urge, then message me if it is not zero.',
      ),
      Place(
        id: 'place-sam-work',
        participantId: 'user-sam',
        name: 'Loading dock',
        kind: PlaceKind.highRisk,
        note: 'Step outside and text Morgan before the break ends.',
      ),
      Place(
        id: 'place-sam-gym',
        participantId: 'user-sam',
        name: 'Community gym',
        kind: PlaceKind.healthy,
        note: 'You wanted movement on hard days. You are in the right building.',
      ),
    ]);

    goals['user-jordan'] =
        'Text Morgan and move to a supportive place before using.';
    for (final user in users) {
      goals.putIfAbsent(
        user.id,
        () => 'Take one step that makes use less likely today.',
      );
    }

    const moods = [
      'Low',
      'Okay',
      'Good',
      'Okay',
      'Very low',
      'Steady',
      'Good',
      'Okay',
      'Low',
      'Good',
      'Steady',
      'Okay',
      'Good',
    ];
    const dailyOffsets = [1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14];
    const useOffsets = {1, 3, 6, 10, 13};
    for (var i = 0; i < dailyOffsets.length; i++) {
      final offset = dailyOffsets[i];
      surveys.add(
        SurveyRecord(
          id: 'survey-daily-$offset',
          participantId: 'user-jordan',
          kind: SurveyKind.daily,
          at: now.subtract(Duration(days: offset, hours: 2)),
          mood: moods[i],
          use: useOffsets.contains(offset)
              ? (offset == 3 ? 'Other drugs' : 'Alcohol')
              : 'No',
          context: 'Home',
          goal: 'Partly',
        ),
      );
    }
    surveys.add(
      SurveyRecord(
        id: 'survey-loc-2',
        participantId: 'user-jordan',
        kind: SurveyKind.location,
        at: now.subtract(const Duration(days: 2, hours: 5)),
        mood: 'Low',
        intent: 'Moderate',
        context: 'Alone',
        present: true,
        placeId: 'place-bar',
      ),
    );
    surveys.add(
      SurveyRecord(
        id: 'survey-healthy-4',
        participantId: 'user-jordan',
        kind: SurveyKind.healthy,
        at: now.subtract(const Duration(days: 4, hours: 3)),
        mood: 'Good',
        present: true,
        placeId: 'place-park',
      ),
    );
    surveys.add(
      SurveyRecord(
        id: 'survey-sam-daily',
        participantId: 'user-sam',
        kind: SurveyKind.daily,
        at: now.subtract(const Duration(days: 1, hours: 3)),
        mood: 'Okay',
        use: 'No',
        context: 'Work',
        goal: 'Yes',
      ),
    );

    alerts.add(
      PeerAlert(
        id: 'alert-1',
        peerId: 'peer-morgan',
        participantId: 'user-jordan',
        placeName: 'Main Street Bar',
        at: now.subtract(const Duration(days: 2, hours: 5)),
      ),
    );

    messages.addAll([
      ChatMessage(
        id: 'msg-1',
        participantId: 'user-jordan',
        peerId: 'peer-morgan',
        senderId: 'peer-morgan',
        senderRole: UserRole.peer,
        body: 'Text me if you are near Main Street tonight.',
        at: now.subtract(const Duration(days: 1, hours: 8)),
      ),
      ChatMessage(
        id: 'msg-2',
        participantId: 'user-jordan',
        peerId: 'peer-morgan',
        senderId: 'user-jordan',
        senderRole: UserRole.participant,
        body: 'I walked to the park instead.',
        at: now.subtract(const Duration(days: 1, hours: 7)),
      ),
      ChatMessage(
        id: 'msg-3',
        participantId: 'user-jordan',
        peerId: 'peer-morgan',
        senderId: 'peer-morgan',
        senderRole: UserRole.peer,
        header: 'Morning plan',
        body: 'You wanted a check-in before noon. Tell me how the morning feels.',
        at: now.subtract(const Duration(days: 3)),
        scheduledFor: now.add(const Duration(days: 1, hours: 1)),
      ),
    ]);

    final tomorrow = dateOnly(now).add(const Duration(days: 1, hours: 15));
    events.add(
      CalendarEvent(
        id: 'event-1',
        participantId: 'user-jordan',
        title: 'Peer check-in',
        start: tomorrow,
        location: 'Clinic lobby',
        notes: 'Talk through the week and any new places to flag.',
        createdBy: 'Morgan Blake',
      ),
    );
  }
}

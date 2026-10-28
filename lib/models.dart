enum UserRole { participant, peer, admin }

enum PlaceKind { highRisk, healthy }

enum SurveyKind { daily, location, healthy }

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.active,
    required this.createdAt,
    this.peerId,
  });

  final String id;
  final String name;
  final String email;
  String password;
  UserRole role;
  bool active;
  final DateTime createdAt;
  String? peerId;

  String get roleLabel => switch (role) {
        UserRole.participant => 'Participant',
        UserRole.peer => 'Peer',
        UserRole.admin => 'Org admin',
      };
}

class PendingSignup {
  PendingSignup({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

class Place {
  Place({
    required this.id,
    required this.participantId,
    required this.name,
    required this.kind,
    required this.note,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String participantId;
  final String name;
  final PlaceKind kind;
  final String note;
  final double? latitude;
  final double? longitude;

  bool get isHighRisk => kind == PlaceKind.highRisk;
}

class SurveyRecord {
  SurveyRecord({
    required this.id,
    required this.participantId,
    required this.kind,
    required this.at,
    this.mood,
    this.use,
    this.intent,
    this.context,
    this.goal,
    this.present,
    this.placeId,
  });

  final String id;
  final String participantId;
  final SurveyKind kind;
  final DateTime at;
  final String? mood;
  final String? use;
  final String? intent;
  final String? context;
  final String? goal;
  final bool? present;
  final String? placeId;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.participantId,
    required this.peerId,
    required this.senderId,
    required this.senderRole,
    required this.body,
    required this.at,
    this.header,
    this.scheduledFor,
  });

  final String id;
  final String participantId;
  final String peerId;
  final String senderId;
  final UserRole senderRole;
  final String body;
  final DateTime at;
  final String? header;
  final DateTime? scheduledFor;

  bool isScheduled(DateTime now) =>
      scheduledFor != null && scheduledFor!.isAfter(now);
}

class PeerAlert {
  PeerAlert({
    required this.id,
    required this.peerId,
    required this.participantId,
    required this.placeName,
    required this.at,
    this.read = false,
  });

  final String id;
  final String peerId;
  final String participantId;
  final String placeName;
  final DateTime at;
  bool read;
}

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.participantId,
    required this.title,
    required this.start,
    required this.location,
    required this.notes,
    required this.createdBy,
  });

  final String id;
  final String participantId;
  final String title;
  final DateTime start;
  final String location;
  final String notes;
  final String createdBy;
}

class ContactNote {
  ContactNote({
    required this.id,
    required this.fromEmail,
    required this.subject,
    required this.body,
    required this.at,
  });

  final String id;
  final String fromEmail;
  final String subject;
  final String body;
  final DateTime at;
}

class WeekSummary {
  const WeekSummary({
    required this.dailyCount,
    required this.useDays,
    required this.locationCount,
  });

  final int dailyCount;
  final int useDays;
  final int locationCount;
}

class ResourceArticle {
  const ResourceArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.paragraphs,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> paragraphs;
}

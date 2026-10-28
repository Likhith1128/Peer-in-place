# Peer in Place

Flutter app for a GPS-triggered recovery support study. One codebase runs on Android, iOS, and the web.

Participants flag up to five places. Entering a high-risk place opens a short survey (presence, mood, intent to use, social context) and alerts the assigned peer. Supportive places show kudos and the participant’s goal. A morning survey, mood and use trends, saved learning modules, in-app messages, and a help screen with crisis numbers are included. Peers see a caseload. Admins manage the directory and can export a CSV.

This is a session prototype. Accounts and answers stay in memory on the device. It does not replace treatment or contact emergency services.

## Prototype logins

Password for every sample account: `peerplace`

| Role | Email |
| --- | --- |
| Participant | jordan@peerinplace.app |
| Peer | morgan@peerinplace.app |
| Admin | alex@peerinplace.app |

New accounts use a verification code:

- `PIP-PARTICIPANT`
- `PIP-PEER`
- `PIP-ADMIN`

## Run

```bash
flutter pub get
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

Web build:

```bash
flutter build web
```

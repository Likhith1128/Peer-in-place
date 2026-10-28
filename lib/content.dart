import 'models.dart';

const articles = <ResourceArticle>[
  ResourceArticle(
    id: 'use',
    title: 'Substance use',
    subtitle: 'Urges, patterns, and what this app is for',
    paragraphs: [
      'Peer in Place is a study support tool. It does not diagnose anyone and it does not replace treatment or a crisis service.',
      'Urges often rise in particular places and then fall. The morning survey and the location survey are there to catch that moment while it is still small.',
      'During the two-week active period, a location survey opens again every time a flagged place is entered.',
    ],
  ),
  ResourceArticle(
    id: 'mood',
    title: 'Mood',
    subtitle: 'A short daily read on how the day starts',
    paragraphs: [
      'The morning survey asks for mood, any use since yesterday, who was around, and whether a goal got any attention.',
      'Trends on the home dashboard turn those answers into a line over time so a hard day is visible in context.',
      'Saving this module keeps it next to the survey if you want to reread it before you answer.',
    ],
  ),
  ResourceArticle(
    id: 'contexts',
    title: 'People and places',
    subtitle: 'Contexts that make use more or less likely',
    paragraphs: [
      'Each participant can flag up to five places. A place is either high-risk or supportive.',
      'High-risk entry asks you to confirm you are there, then asks about mood, intent to use, and who is with you.',
      'Your peer gets an alert for a high-risk entry and can message you in the app. Crisis numbers stay in Help.',
    ],
  ),
  ResourceArticle(
    id: 'goals',
    title: 'Goals to reduce use',
    subtitle: 'One step you can actually take',
    paragraphs: [
      'Write a goal in your own words on your profile. The morning survey asks if you took a step toward it.',
      'A supportive place reminds you of that goal. A high-risk place shows a message your peer wrote for that spot.',
      'Goals in this prototype stay on this device for the session.',
    ],
  ),
  ResourceArticle(
    id: 'places',
    title: 'Supportive locations',
    subtitle: 'Kudos when you are somewhere you chose',
    paragraphs: [
      'When a place marked supportive is entered, the app shows kudos, asks for a mood rating, and repeats your goal.',
      'Movement maps are not part of this trial view. The useful record is the mood line and the survey answers.',
      'You can practice an arrival with Arrive on the Flagged places screen if this device has no GPS fix.',
    ],
  ),
];

const demoPassword = 'peerplace';

const participantCode = 'PIP-PARTICIPANT';
const peerCode = 'PIP-PEER';
const adminCode = 'PIP-ADMIN';

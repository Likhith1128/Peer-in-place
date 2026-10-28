// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

bool downloadTextFile(String filename, String content) {
  final blob = html.Blob([content], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}

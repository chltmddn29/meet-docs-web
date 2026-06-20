// 웹 전용: 메모리에 있는 바이트를 사용자 PC로 즉시 내려받게 한다.
// 녹음 업로드가 실패해도 원본이 절대 사라지지 않도록 하는 안전장치.
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// [bytes]를 [filename]으로 브라우저 다운로드시킨다.
/// Blob URL을 만들어 보이지 않는 <a download>를 클릭한 뒤 정리한다.
void downloadBytes(
  List<int> bytes,
  String filename, {
  String mimeType = 'application/octet-stream',
}) {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

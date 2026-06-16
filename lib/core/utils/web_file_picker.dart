import 'dart:async';
// 웹 전용 앱이라 dart:html을 직접 사용 (브라우저 파일 입력에 가장 안정적)
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

class PickedFile {
  final Uint8List bytes;
  final String name;
  const PickedFile(this.bytes, this.name);
}

/// 브라우저 기본 `<input type="file">`로 파일 선택 + 바이트 읽기.
/// file_picker 플러그인 대신 웹 네이티브 기능을 써서 웹에서 확실히 동작한다.
/// 사용자가 취소하면 future는 완료되지 않는다(업로드도 진행되지 않음).
Future<PickedFile?> pickFile(List<String> extensions) {
  final completer = Completer<PickedFile?>();
  final input = html.FileUploadInputElement()
    ..accept = extensions.map((e) => '.$e').join(',');

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      final result = reader.result;
      Uint8List? bytes;
      if (result is Uint8List) {
        bytes = result;
      } else if (result is ByteBuffer) {
        bytes = result.asUint8List();
      }
      if (!completer.isCompleted) {
        completer.complete(bytes == null ? null : PickedFile(bytes, file.name));
      }
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}

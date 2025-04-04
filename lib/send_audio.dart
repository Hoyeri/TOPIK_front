import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> sendAudioToServer(String filePath) async { // 반환 타입 수정
  try {
    File audioFile = File(filePath);

    if (!await audioFile.exists()) {
      print("❌ 파일이 존재하지 않습니다: $filePath");
      return {}; // 빈 딕셔너리 반환 (오류 처리)
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://10.0.2.2:5000/upload"),
    );

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      try {
        Map<String, dynamic> jsonData = json.decode(responseBody);
        String text = jsonData['text'];
        String feedback = jsonData['feedback'];

        print("✅ 변환된 텍스트: $text");
        print("✅ 피드백: $feedback");

        return {'text': text, 'feedback': feedback}; // 딕셔너리 반환
      } catch (e) {
        print("❌ JSON 디코딩 오류: $e");
        return {}; // 빈 딕셔너리 반환 (오류 처리)
      }
    } else {
      print("❌ 서버 응답 오류: ${response.statusCode}");
      return {}; // 빈 딕셔너리 반환 (오류 처리)
    }
  } catch (e) {
    print("❌ 전송 중 오류 발생: $e");
    return {}; // 빈 딕셔너리 반환 (오류 처리)
  }
}
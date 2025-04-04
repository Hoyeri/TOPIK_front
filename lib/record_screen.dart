import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'send_audio.dart'; // 서버 통신 함수가 있는 파일
import 'package:permission_handler/permission_handler.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _filePath;
  bool _isInitializing = true;
  int _recordDuration = 0;
  Timer? _timer;
  String? _transcribedText;
  String? _feedbackText;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() => _isInitializing = false);
      return;
    }
    await _recorder!.openRecorder();
    setState(() => _isInitializing = false);
  }

  Future<void> _startRecording() async {
    if (_isRecording || _recorder == null) return;

    var status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return;
      }
    }

    final dir = await getTemporaryDirectory();
    _filePath =
    "${dir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.aac";

    await _recorder!.startRecorder(toFile: _filePath, codec: Codec.aacADTS);
    setState(() {
      _isRecording = true;
      _recordDuration = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _recorder == null) return;

    try {
      String? path = await _recorder!.stopRecorder();
      setState(() => _isRecording = false);
      _timer?.cancel();
      print("녹음 중지됨");
      if (path != null) {
        print("녹음 파일 저장됨: $path");
        _processAudio(path); // 녹음 파일 처리
      }
    } catch (e) {
      print("❌ 녹음 중지 오류: $e");
    }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      _filePath = result.files.single.path;
      _processAudio(_filePath!); // 업로드 파일 처리
    } else {
      print("파일 선택 취소됨");
    }
  }

  Future<void> _processAudio(String filePath) async {
    final result = await sendAudioToServer(filePath);
    if (result.isNotEmpty) {
      setState(() {
        _transcribedText = result['text'];
        _feedbackText = result['feedback'];
        _showResult = true;
      });
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (_recordDuration ~/ 60).toString().padLeft(2, '0');
    String seconds = (_recordDuration % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text('사용자 녹음 화면(예시)'),
      ),
      body: Center(
        child: _isInitializing
            ? CircularProgressIndicator()
            : _showResult
            ? _buildResultScreen()
            : _buildRecordingScreen(minutes, seconds),
      ),
    );
  }

  Widget _buildRecordingScreen(String minutes, String seconds) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '어디에 여행을 가고 싶어요?\n왜 가고 싶어요?\n자유롭게 얘기해 보세요.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? '녹음 중지' : '녹음 시작'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _uploadFile,
              child: Text('파일 업로드'),
            ),
          ],
        ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              '$minutes:$seconds',
              style: TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildResultScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '어디에 여행을 가고 싶어요?\n왜 가고 싶어요?\n자유롭게 얘기해 보세요.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _transcribedText ?? '텍스트 변환 중 오류 발생',
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 20),
          Text(
            '피드백:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            _feedbackText ?? '피드백을 불러오는 중 오류 발생',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showResult = false;
                _transcribedText = null;
                _feedbackText = null;
              });
            },
            child: Text('돌아가기'),
          ),
        ],
      ),
    );
  }
}
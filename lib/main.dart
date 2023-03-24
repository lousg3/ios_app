import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';

void main() => runApp(VoiceAssistantApp());

class VoiceAssistantApp extends StatefulWidget {
  @override
  _VoiceAssistantAppState createState() => _VoiceAssistantAppState();
}

class _VoiceAssistantAppState extends State<VoiceAssistantApp> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  final String _whisperApiKey = 'FNQC6T5Q6G1I5HS4MQGHZWZLNCI2L9BZ';
  late FlutterTts flutterTts;
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    flutterTts = FlutterTts();
  }

  Future<String> _getWhisperResponse(String query) async {
    String url = 'https://api.openai.com/v1/engines/davinci-codex/completions';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_whisperApiKey',
    };
    String prompt = 'Q: $query\nA:';
    String requestBody =
        '{"prompt": "$prompt", "max_tokens": 50, "temperature": 0.7}';
    http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: requestBody,
    );
    Map<String, dynamic> data = jsonDecode(response.body);
    String whisperResponse = data['choices'][0]['text'];
    return whisperResponse;
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      print('Speech-to-text available');
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          setState(() => _text = result.recognizedWords);
          print('Recognized text: $_text');
          if (result.finalResult) {
            String response = await _getWhisperResponse(_text);
            await _speak(response);
          }
        },
      );
    } else {
      print('Speech-to-text not available');
    }
  }


  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Assistant',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Voice Assistant'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _text,
                style: TextStyle(fontSize: 32.0),
              ),
              SizedBox(height: 16.0),
              _isListening
                  ? ElevatedButton(
                onPressed: _stopListening,
                child: Text('Stop Listening'),
              )
                  : ElevatedButton(
                onPressed: _startListening,
                child: Text('Start Listening'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

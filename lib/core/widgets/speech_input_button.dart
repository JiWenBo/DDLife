import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechInputButton extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSpeechStart;
  final VoidCallback? onSpeechEnd;

  const SpeechInputButton({
    super.key,
    required this.controller,
    this.onSpeechStart,
    this.onSpeechEnd,
  });

  @override
  State<SpeechInputButton> createState() => _SpeechInputButtonState();
}

class _SpeechInputButtonState extends State<SpeechInputButton> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      await _speechToText.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              widget.onSpeechEnd?.call();
            }
          }
        },
      );
    } catch (e) {
      debugPrint('STT Initialize Error: $e');
    }
  }

  void _startListening() async {
    // 检查权限
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限才能使用语音输入')),
        );
      }
      return;
    }

    if (!_speechToText.isAvailable) {
      bool available = await _speechToText.initialize();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该设备当前不支持语音识别或正在初始化')),
          );
        }
        return;
      }
    }

    // 开始录音前，保存当前已有的文字
    _previousText = widget.controller.text;
    widget.onSpeechStart?.call();
    
    await _speechToText.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          // 如果原本有文字，加个空格拼接，如果没有则直接使用识别结果
          final newText = _previousText.isEmpty 
              ? result.recognizedWords 
              : '$_previousText ${result.recognizedWords}'.trim();
          
          widget.controller.text = newText;
          // 移动光标到最后
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length)
          );
        });
      },
      localeId: 'zh_CN', // 默认使用中文识别
      cancelOnError: true,
      partialResults: true,
    );
    
    if (mounted) {
      setState(() => _isListening = true);
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() => _isListening = false);
      widget.onSpeechEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        color: _isListening ? Colors.blue : Colors.grey,
      ),
      onPressed: _isListening ? _stopListening : _startListening,
      tooltip: _isListening ? '停止录音' : '语音输入',
    );
  }
}

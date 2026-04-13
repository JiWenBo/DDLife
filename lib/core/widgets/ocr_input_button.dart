import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class OcrInputButton extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onOcrStart;
  final VoidCallback? onOcrEnd;

  const OcrInputButton({
    super.key,
    required this.controller,
    this.onOcrStart,
    this.onOcrEnd,
  });

  @override
  State<OcrInputButton> createState() => _OcrInputButtonState();
}

class _OcrInputButtonState extends State<OcrInputButton> {
  final ImagePicker _picker = ImagePicker();
  // 指定识别中文
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  bool _isProcessing = false;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processImage(ImageSource source) async {
    // 检查权限
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要相机权限才能拍照识别')),
          );
        }
        return;
      }
    } else {
      // 相册权限在较新iOS版本中可能有不同表现，这里使用统一请求
      final status = await Permission.photos.request();
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('需要相册权限才能选择照片识别')),
          );
        }
        return;
      }
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isProcessing = true);
      widget.onOcrStart?.call();

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // 简单处理：将所有识别到的文字拼接起来，去掉换行
      String text = recognizedText.text.replaceAll('\n', ' ').trim();

      if (mounted) {
        if (text.isNotEmpty) {
           // 如果原本有文字，加个空格拼接，如果没有则直接使用识别结果
          // final previousText = widget.controller.text;
          // final newText = text;
          
          widget.controller.text = text;
          // 移动光标到最后
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length)
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未能从图片中识别出文字')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别出错: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        widget.onOcrEnd?.call();
      }
    }
  }

  void _showSourceDialog() {
    // 按照您的要求，直接跳过选择相册，直接调用拍照
    _processImage(ImageSource.camera);
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.camera, color: Colors.grey),
      onPressed: _showSourceDialog,
      tooltip: '拍照识字',
    );
  }
}

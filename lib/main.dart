import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:ui' as ui;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HandwritingScreen(),
    );
  }
}

class HandwritingScreen extends StatefulWidget {
  const HandwritingScreen({super.key});

  @override
  HandwritingScreenState createState() => HandwritingScreenState();
}

class HandwritingScreenState extends State<HandwritingScreen> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  String _ocrResult = '';
  double _strokeWidth = 4.0;
  Color _strokeColor = Colors.black;
  // String? _savedImagePath;

  Future<void> _performOCR(String imagePath) async {
    try {
      print("Starting OCR with image path: $imagePath");
      final inputImage = InputImage.fromFilePath(imagePath);

      final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      setState(() {
        _ocrResult = recognizedText.text;
      });
      print("OCR Result: $_ocrResult");
    } catch (e) {
      print("OCR Error: $e");
    }
  }

  Future<void> _onSave() async {
    try {
      final signaturePad = _signaturePadKey.currentState;
      if (signaturePad != null) {
        ui.Image image = await signaturePad.toImage(pixelRatio: 6.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          Uint8List pngBytes = byteData.buffer.asUint8List();
          print("Image bytes length: ${pngBytes.length}");

          final directory = await getApplicationDocumentsDirectory();
          final imagePath = '${directory.path}/handwritten_image.png';
          final imageFile = File(imagePath);
          await imageFile.writeAsBytes(pngBytes);
          // setState(() {
          //   _savedImagePath = imagePath;
          // });
          print("Image saved to: $imagePath");

          _performOCR(imagePath);
        } else {
          print("ByteData is null");
        }
      } else {
        print("SignaturePad is null");
      }
    } catch (e) {
      print("Save Error: $e");
    }
  }

  void _onDrawEnd() {
    _onSave();
  }

  void _reset() {
    setState(() {
      _ocrResult = '';
      // _savedImagePath = null;
    });
    _signaturePadKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手書き入力とOCR'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _ocrResult,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 300,
            padding: const EdgeInsets.all(16.0),
            child: SfSignaturePad(
              key: _signaturePadKey,
              minimumStrokeWidth: _strokeWidth,
              maximumStrokeWidth: _strokeWidth,
              strokeColor: _strokeColor,
              backgroundColor: Colors.grey[200],
              onDrawEnd: _onDrawEnd,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('線の太さ: '),
              Slider(
                value: _strokeWidth,
                min: 1,
                max: 10,
                divisions: 9,
                label: _strokeWidth.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _strokeWidth = value;
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('線の色: '),
              IconButton(
                icon: Icon(Icons.color_lens, color: _strokeColor),
                onPressed: () async {
                  Color? selectedColor = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('色を選択'),
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: _strokeColor,
                          onColorChanged: (color) {
                            setState(() {
                              _strokeColor = color;
                            });
                          },
                        ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          child: const Text('完了'),
                          onPressed: () {
                            Navigator.of(context).pop(_strokeColor);
                          },
                        ),
                      ],
                    ),
                  );
                  if (selectedColor != null) {
                    setState(() {
                      _strokeColor = selectedColor;
                    });
                  }
                },
              ),
            ],
          ),
          // if (_savedImagePath != null) ...[
          //   const Text('保存した画像のプレビュー:'),
          //   Expanded(child: Builder(
          //     builder: (context) {
          //       return Image.file(File(_savedImagePath!));
          //     }
          //   )),
          // ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _reset,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

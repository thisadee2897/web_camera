// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraWebScreen extends StatefulWidget {
  const CameraWebScreen({super.key});

  @override
  State<CameraWebScreen> createState() => _CameraWebScreenState();
}

class _CameraWebScreenState extends State<CameraWebScreen> {
  html.VideoElement? _videoElement;
  String _selectedCamera = 'environment'; // 'user' = front, 'environment' = back
  List<String> capturedImages = []; // เก็บรูปภาพที่ถ่าย
@override
void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openCamera();
    });
  }
  // เปิดกล้องตามประเภทที่เลือก
  void openCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': _selectedCamera,
        },
        'audio': false,
      });

      _videoElement = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..style.width = '100%'
        ..style.height = '100%';

      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'camera-view',
        (int viewId) => _videoElement!,
      );

      setState(() {});
    } catch (error) {
      if (kDebugMode) print('Error accessing camera: $error');
    }
    
  }

  // ถ่ายรูปจาก Video Element
  void capturePhoto() {
    if (_videoElement != null) {
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );

      final context = canvas.context2D;
      context.drawImage(_videoElement!, 0, 0);

      // แปลงเป็น Base64 สำหรับแสดงผล
      final dataUrl = canvas.toDataUrl('image/png');

      setState(() {
        capturedImages.add(dataUrl); // เก็บรูปถ่าย
      });
    }
  }

  // ทำลายกล้องเมื่อปิดหน้าจอ
  @override
  void dispose() {
    _videoElement?.srcObject?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Web Camera')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // แสดงกล้อง
              if (_videoElement != null)
                Container(
                  width: 400,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HtmlElementView(viewType: 'camera-view'),
                ),

              const SizedBox(height: 10),

              // ปุ่มถ่ายรูป
              if (_videoElement != null)
                ElevatedButton(
                  onPressed: capturePhoto,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('ถ่ายรูป', style: TextStyle(color: Colors.white)),
                ),

              const SizedBox(height: 20),

              // แสดงรูปถ่าย
              if (capturedImages.isNotEmpty)
                const Text(
                  'รูปถ่ายที่ผ่านมา:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: capturedImages.map((image) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image,
                      width: 150,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

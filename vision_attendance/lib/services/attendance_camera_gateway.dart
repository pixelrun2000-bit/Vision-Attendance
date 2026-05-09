import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'face_match_evaluator.dart';

abstract class AttendanceCameraGateway {
  bool get isReady;
  Future<void> initialize();
  Widget buildPreview();
  Future<FaceScanFrame> captureFrame();
  Future<void> dispose();
}

class DeviceAttendanceCameraGateway implements AttendanceCameraGateway {
  CameraController? _controller;

  @override
  bool get isReady => _controller?.value.isInitialized ?? false;

  @override
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera available on this device.');
    }

    final selected = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    await controller.setFlashMode(FlashMode.off);
    _controller = controller;
  }

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return CameraPreview(controller);
  }

  @override
  Future<FaceScanFrame> captureFrame() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw Exception('Camera is not initialized.');
    }

    final file = await controller.takePicture();
    final size = await file.length();
    return FaceScanFrame(bytesLength: size);
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}

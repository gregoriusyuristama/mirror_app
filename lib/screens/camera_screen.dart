import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;
  // bool showFocusCircle = false;
  // double x = 0;
  // double y = 0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;
  double _baseScaleFactor = 1.0;

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
      await cameraController
          .lockCaptureOrientation(DeviceOrientation.portraitUp);
      cameraController
          .getMaxZoomLevel()
          .then((value) => _maxAvailableZoom = value);

      cameraController
          .getMinZoomLevel()
          .then((value) => _minAvailableZoom = value);
    } on CameraException catch (e) {
      showInSnackBar('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    try {
      onNewCameraSelected(cameras[1]);
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing camera: $e');
      }
    }
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? Container(
              color: Colors.black,
              child: SafeArea(
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onScaleStart: (details) {
                          _baseScaleFactor = _currentZoomLevel;
                        },
                        onScaleUpdate: (details) async {
                          _currentZoomLevel = details.scale * _baseScaleFactor;
                          if (_currentZoomLevel < _minAvailableZoom) {
                            _currentZoomLevel = _minAvailableZoom;
                          } else if (_currentZoomLevel > _maxAvailableZoom) {
                            _currentZoomLevel = _maxAvailableZoom;
                          }
                          setState(() {});
                          controller!.setZoomLevel(_currentZoomLevel);
                        },
                        onScaleEnd: (details) {
                          controller!.setZoomLevel(_currentZoomLevel);
                        },
                        child: AspectRatio(
                          aspectRatio: 1 / controller!.value.aspectRatio,
                          child: controller!.buildPreview(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _currentZoomLevel,
                        min: _minAvailableZoom,
                        max: _maxAvailableZoom,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        onChanged: (value) async {
                          setState(() {
                            _currentZoomLevel = value;
                          });
                          await controller!.setZoomLevel(value);
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${_currentZoomLevel.toStringAsFixed(1)}x',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Camera initialization error',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, DeviceOrientation;

import 'screens/camera_screen.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    cameras = await availableCameras();
  } on CameraException catch (e) {
    if (kDebugMode) {
      print('Error in fetching the cameras: $e');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pocket Mirror',
      debugShowCheckedModeBanner: false,
      home: CameraScreen(),
    );
  }
}

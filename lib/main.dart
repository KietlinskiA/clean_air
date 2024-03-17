import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'model/location_data.dart';
import 'screen/splash_screen.dart';

Future<void> main() async {
  dotenv.load(fileName: 'config.env').then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(locationData: LocationData.empty()),
    );
  }
}

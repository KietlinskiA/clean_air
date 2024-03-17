import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:weather/weather.dart';

import '../config/app_config.dart';
import '../config/my_logger.dart';
import '../model/location_data.dart';
import 'home_page_screen.dart';
import 'permission_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.locationData});

  final LocationData locationData;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Logger logger = AppLogger().logger;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
              decoration: const BoxDecoration(
            color: Color(0xffffffff),
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xff6671E5), Color(0xff4852D9)]),
          )),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/cloud-sun.png'),
                const SizedBox(height: 14.0),
                Text(
                  'Clean Air',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 42.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Aplikacja do monitorowania\nczystości powietrza.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    textStyle:
                        const TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          Positioned(
              left: 0.0,
              bottom: 35.0,
              right: 0.0,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Przywiewam dane...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w300),
                  ),
                ),
              ))
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    logger.d('Checking permission');
    checkPermission();
  }

  void checkPermission() async {
    var gpsPerm = await Permission.location.status;
    logger.d('Get GPS status: $gpsPerm');

    if (context.mounted) {
      logger.d('Context mounted');
      logger.i('Permission status: $gpsPerm');
      if (gpsPerm.isDenied || gpsPerm.isPermanentlyDenied) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const PermissionScreen()));
      } else {
        while (await Permission.location.serviceStatus.isDisabled) {
          logger.w('Location service is disabled');
          await showLocationSettingsDialog();
        }
        logger.d('Location service is enabled');
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          executeOnceAfterBuild();
        });
      }
    } else {
      logger.d('Context NOT mounted');
    }
  }

  void executeOnceAfterBuild() async {
    if (widget.locationData != LocationData.empty()) {
      Position position = Position(
          longitude: widget.locationData.lng,
          latitude: widget.locationData.lat,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0);
      loadLocationData(position, LoadLocationData.custom);
    } else {
      Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.bestForNavigation,
              forceAndroidLocationManager: true,
              timeLimit: const Duration(seconds: 5))
          .then((value) => {loadLocationData(value, LoadLocationData.current)})
          .onError((error, stackTrace) => {
                Geolocator.getLastKnownPosition(
                  forceAndroidLocationManager: true,
                ).then((value) => {
                      value != null
                          ? loadLocationData(value, LoadLocationData.last)
                          : showLocationSettingsDialog()
                    })
              });
    }
  }

  void loadLocationData(Position position, String type) async {
    logger.d('Load location data from $type position');
    logger.d('Position: ${position.toString()}');
    var lat = position.latitude;
    var lon = position.longitude;

    Weather w = await getWeatherData(lat, lon);
    AirQuality aq = await getAirData(lat, lon);
    LocationData locationData = await getLocationData(position);

    if (context.mounted) {
      logger.i('Location data loaded successfully');
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MyHomePage(weather: w, air: aq, locationData: locationData)));
    }
  }

  Future<LocationData> getLocationData(Position position) async {
    List<LocationData> locations =
        await LocationData.getLocations(LocationData.empty()
          ..lat = position.latitude
          ..lng = position.longitude);
    LocationData locationData = locations.first;
    logger.t('LOCATION $locationData');
    return locationData;
  }

  Future<AirQuality> getAirData(double lat, double lon) async {
    var keyword = 'geo:$lat;$lon';
    String endpoint = 'https://api.waqi.info/feed/';
    var key = AppConfig.airKey;
    String url = '$endpoint$keyword/?token=$key';

    http.Response response = await http.get(Uri.parse(url));
    logger.t('AIR ${response.body}');

    Map<String, dynamic> jsonBody = json.decode(response.body);
    AirQuality aq = AirQuality(jsonBody);
    return aq;
  }

  Future<Weather> getWeatherData(double lat, double lon) async {
    WeatherFactory wf =
        WeatherFactory(AppConfig.weatherKey, language: Language.POLISH);
    Weather w = await wf.currentWeatherByLocation(lat, lon);
    logger.t('WEATHER ${w.toJson()}');
    return w;
  }

  Future<void> showLocationSettingsDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
          title: Text(
            'Włącz lokalizację',
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                  height: 1.2,
                  fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Aby korzystać z aplikacji, włącz lokalizację.',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 14.0, height: 1.2, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ok',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 16.0,
                        height: 1.2,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  )),
              onPressed: () {
                Geolocator.isLocationServiceEnabled()
                    .then((value) => Navigator.of(context).pop());
              },
            ),
            TextButton(
              child: Text('Ustawienia',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 16.0,
                        height: 1.2,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  )),
              onPressed: () {
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }
}

class LoadLocationData {
  static const current = 'CURRENT';
  static const last = 'LAST';
  static const custom = 'CUSTOM';
}

class AirQuality {
  final Logger logger = AppLogger().logger;

  bool isGood = false;
  bool isBad = false;
  String quality = '';
  String advice = '';
  int aqi = 0;
  int pm25 = 0;
  int pm10 = 0;
  String station = '';

  AirQuality(Map<String, dynamic> jsonBody) {
    if(jsonBody['data'] == null || jsonBody['data'] is String) {
      logger.f('Problem with data from AIR endpoint!');
      logger.f(jsonBody['data']);
    }

    aqi = int.tryParse(jsonBody['data']['aqi'].toString()) ?? -1;
    if (jsonBody['data']['iaqi']['pm25'] != null &&
        jsonBody['data']['iaqi']['pm25']['v'] != null) {
      pm25 =
          int.tryParse(jsonBody['data']['iaqi']['pm25']['v'].toString()) ?? -1;
    } else {
      pm25 = -1;
    }
    if (jsonBody['data']['iaqi']['pm10'] != null &&
        jsonBody['data']['iaqi']['pm10']['v'] != null) {
      pm10 =
          int.tryParse(jsonBody['data']['iaqi']['pm10']['v'].toString()) ?? -1;
    } else {
      pm10 = -1;
    }
    station = jsonBody['data']['city']['name'].toString();
    setupLevel(aqi);
  }

  void setupLevel(int aqi) {
    if (aqi <= 100) {
      quality = 'Bardzo dobra';
      advice = 'Skorzystaj z dobrego powietrza i wyjdź na spacer';
      isGood = true;
    } else if (aqi <= 150) {
      quality = 'Nie za dobra';
      advice = 'Jeśli tylko możesz zostań w domu, załatwiaj sprawy online';
      isBad = true;
    } else {
      quality = 'Bardzo zła!';
      advice = 'Zdecydowanie zostań w domu i załatwiaj sprawy online!';
    }
  }
}

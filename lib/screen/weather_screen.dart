
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.weather});

  final Weather weather;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
              decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  gradient: getGradientByMood(widget.weather)
              )),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 45.0),
                Image.asset('assets/${getIconByMood(widget.weather)}.png'),
                const SizedBox(height: 41.0),
                Text(
                  toBeginningOfSentenceCase(DateFormat.MMMMEEEEd('pl').format(DateTime.now()))!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  '${widget.weather.temperature?.celsius?.floor()
                      .toString()}°C',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 64.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  'Odczuwalna ${widget.weather.tempFeelsLike?.celsius
                      ?.floor()}°C',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24.0),
                IntrinsicHeight(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 130,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Ciśnienie',
                                  style: GoogleFonts.lato(
                                    textStyle: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300),
                                  )),
                              Text('${widget.weather.pressure?.floor()} hPa',
                                  style: GoogleFonts.lato(
                                    textStyle: const TextStyle(
                                        fontSize: 22.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ))
                            ],
                          ),
                        ),
                        const VerticalDivider(
                          width: 36.0,
                        ),
                        SizedBox(
                          width: 130,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('Wiatr',
                                  style: GoogleFonts.lato(
                                    textStyle: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300),
                                  )),
                              Text('${widget.weather.windSpeed} m/s',
                                  style: GoogleFonts.lato(
                                    textStyle: const TextStyle(
                                        fontSize: 22.0,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ))
                            ],
                          ),
                        ),
                      ]),
                ),
                const SizedBox(height: 25.0),
                if (widget.weather.rainLastHour != null)
                  Text(
                    'Opady: ${widget.weather.rainLastHour} mm / 1h',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pl', null);
  }

  LinearGradient getGradientByMood(Weather weather) {
    var main = weather.weatherMain;
    if (main == 'Thunderstorm' || isNight(weather)) {
      return const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xff313545), Color(0xff121118)]);
    } else if (main == 'Clouds' || main == 'Drizzle' || main == 'Snow') {
      return const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xff6E6CD8),
            Color(0xff40A0EF),
            Color(0xff77E1EE)
          ]);
    } else {
      return const LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [Color(0xff5283F0), Color(0xffCDEDD4)]);
    }
  }

  bool isNight(Weather weather) {
    return DateTime.now().isAfter(weather.sunset!) ||
        DateTime.now().isBefore(weather.sunrise!);
  }

  String getIconByMood(Weather weather) {
    var main = weather.weatherMain;
    if (isNight(weather)) {
      return 'weather-moonny';
    } else if (main == 'Clouds' || main == 'Drizzle' || main == 'Snow') {
      return 'weather-rain';
    } else if (main == 'Thunderstorm') {
      return 'weather-lightning';
    } else {
      return 'weather-sunny';
    }
  }
}

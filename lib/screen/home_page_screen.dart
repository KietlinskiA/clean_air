import 'package:flutter/material.dart';
import 'package:weather/weather.dart';

import '../model/location_data.dart';
import 'air_screen.dart';
import 'splash_screen.dart';
import 'weather_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key,
      required this.weather,
      required this.air,
      required this.locationData});

  final Weather weather;
  final AirQuality air;
  final LocationData locationData;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  List<Widget> screens = [];

  @override
  void initState() {
    screens = [
      AirScreen(air: widget.air, locationData: widget.locationData),
      WeatherScreen(weather: widget.weather)
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          color: Colors.white,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black45,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            iconSize: 40,
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(Icons.home_rounded,
                      color: Colors.black, size: 34),
                  label: 'Powietrze',
                  activeIcon: Container(
                      padding: EdgeInsets.zero,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 34,
                      ))),
              BottomNavigationBarItem(
                  icon: const Icon(
                    Icons.cloud_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                  label: 'Pogoda',
                  activeIcon: Container(
                      padding: EdgeInsets.zero,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(
                        Icons.cloud_rounded,
                        color: Colors.white,
                        size: 30,
                      ))),
            ],
          ),
        ));
  }
}

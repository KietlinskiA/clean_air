
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'splash_screen.dart';
import '../model/location_data.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
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
                Image.asset('assets/hand-wave.png'),
                const SizedBox(height: 14.0),
                Text(
                  'Hejka!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 42.0,
                        height: 1.2,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Aplikacja Clean Air pozwoli Ci śledzić aktualny\npoziom zanieczyszczenia powietrza.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 16.0, height: 1.2, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          Positioned(
              left: 0.0,
              bottom: 23.0,
              right: 0.0,
              child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith(
                                (states) => Colors.white),
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.only(top: 10.0, bottom: 10.0)),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0)))),
                        onPressed: () async {
                          await hasPermission(context);
                        },
                        child: Text('Zaczynamy!',
                            style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                  fontSize: 16.0,
                                  height: 1.2,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ))),
                  )))
        ],
      ),
    );
  }

  Future<void> hasPermission(BuildContext context) async {
    var request = await Permission.location.request();
    if (context.mounted) {
      if (request.isPermanentlyDenied || request.isDenied) {
        showPermissionDeniedBox();
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SplashScreen(
                      locationData: LocationData.empty(),
                    )));
      }
    }
  }

  Future<void> showPermissionDeniedBox() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
          title: Text(
            'Brak uprawnień',
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
                  'Uprawnienia do przybliżonej lokalizacji zostały wyłączone dla'
                  ' tej aplikacji.\nAby kontynuować sprawdź uprawnienia w '
                  'ustawieniach telefonu.',
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
              child: Text('Rozumiem',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 16.0,
                        height: 1.2,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  )),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

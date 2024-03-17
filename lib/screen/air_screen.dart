
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../model/location_data.dart';
import '../config/my_logger.dart';
import '../screen/splash_screen.dart';

class AirScreen extends StatefulWidget {
  const AirScreen({super.key, required this.air, required this.locationData});

  final AirQuality air;
  final LocationData locationData;

  @override
  State<AirScreen> createState() => _AirScreenState();
}

class _AirScreenState extends State<AirScreen>
    with SingleTickerProviderStateMixin {
  final Logger logger = AppLogger().logger;
  final GlobalKey<_AirScreenState> myWidgetKey = GlobalKey<_AirScreenState>();

  List<LocationData> _locations = [];
  late LocationData _selectedLocation;
  late String findLocationImage;
  late String findLocationText;

  static const String assetFindNewLocation = 'assets/find-new-location.png';
  static const String assetNotFoundLocation = 'assets/not-found-location.png';
  // TODO: i18n
  static const String textFindNewLocation = 'Znajdź wybraną lokalizację!';
  static const String textNotFoundLocation = 'Nie znaleziono lokalizacji';

  late Animation<double> _scaleAnimationStart;
  late AnimationController _controller;
  bool isVisible = false;
  final PanelController _panelController = PanelController();
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.locationData;
    findLocationImage = assetFindNewLocation;
    findLocationText = textFindNewLocation;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimationStart = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
              decoration: BoxDecoration(
            color: const Color(0xffffffff),
            gradient: getGradientByMood(widget.air),
          )),
          isVisible ? buildFindLocationView() : buildShowInformationView(),
          if (!isVisible) buildDangerValueContainer(),
          if (!isVisible) buildAdviceContainer(),
          if (!isVisible) buildSlidingUpPanel()
        ],
      ),
    );
  }

  void _findLocation(String value) async {
    value = value.trim();
    if (value.isEmpty) {
      logger.d('Location to find from TextField is empty.');
      return;
    }

    LocationData locationData = LocationData.empty()..name = value;
    var newLocations = await LocationData.getLocations(locationData);

    if (newLocations.isEmpty) {
      logger.d('Location not found.');
      setState(() {
        findLocationImage = assetNotFoundLocation;
        findLocationText = textNotFoundLocation;
      });
    } else if (newLocations.length == 1) {
      logger.d('Only one result found. Push to show information.');
      _changeSelectedLocation(newLocations.first);
    } else {
      logger.d('Finded locations: ');
      for (var element in _locations) {
        logger.d(element.toString());
      }
      setState(() {
        _locations = newLocations;
      });
    }
  }

  void _changeLocationDialog() {
    setState(() {
      isVisible = !isVisible;
      logger.d('Change location dialog is visible: $isVisible');

      if (isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
        _locations = List.empty();
        _textEditingController.clear();
      }
    });
  }

  void _changeSelectedLocation(LocationData location) {
    _selectedLocation = location;
    logger.i('New selected location: $_selectedLocation');
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SplashScreen(
                  locationData: _selectedLocation,
                )));
  }

  LinearGradient getGradientByMood(AirQuality air) {
    if (air.isGood) {
      return const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xff4acf8c),
            Color(0xff75eda6),
          ]);
    } else if (air.isBad) {
      return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfffbda61), Color(0xfff76b1c)]);
    } else {
      return const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xfff4003a), Color(0xffff8888)]);
    }
  }

  Color getBackgroundTextColor(AirQuality air) {
    if (air.isGood || air.isBad) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  String getAdviceImage(AirQuality air) {
    if (air.isGood) {
      return 'assets/happy.png';
    } else if (air.isBad) {
      return 'assets/ok.png';
    } else {
      return 'assets/sad.png';
    }
  }

  Image getDangerValueBottom(AirQuality air) {
    if (air.isGood || air.isBad) {
      return Image.asset('assets/danger-value-negative.png');
    } else {
      return Image.asset('assets/danger-value.png');
    }
  }

  Image getDangerValueTop(AirQuality air) {
    if (air.isGood) {
      return Image.asset('assets/danger-value-negative.png',
          color: const Color(0xff4acf8c));
    } else if (air.isBad) {
      return Image.asset('assets/danger-value-negative.png',
          color: const Color(0xfffbda61));
    } else {
      return Image.asset('assets/danger-value.png',
          color: const Color(0xfff4003a));
    }
  }

  Widget buildFindLocationView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 60.0),
          child: Container(
            height: 35.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(width: 6.0),
                      Image.asset('assets/map-pin.png', color: Colors.black),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          maxLength: 50,
                          maxLengthEnforcement:
                              MaxLengthEnforcement.truncateAfterCompositionEnds,
                          maxLines: 1,
                          controller: _textEditingController,
                          onSubmitted: (value) => _findLocation(value),
                          textAlignVertical: TextAlignVertical.top,
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              fontSize: 16.0,
                              height: 1.2,
                              color: Colors.black,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            isDense: false,
                            isCollapsed: true,
                            hintText: 'Szukaj',
                            counterText: '',
                            border: InputBorder.none,
                            alignLabelWithHint: false,
                          ),
                        ),
                      ),
                      // SizedBox(width: 6.0),
                      IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          onPressed: () => {
                                _textEditingController.clear(),
                                setState(() {
                                  _locations.clear();
                                  findLocationImage = assetFindNewLocation;
                                  findLocationText = textFindNewLocation;
                                })
                              },
                          icon: const Icon(Icons.close, color: Colors.grey))
                    ],
                  ),
                ),
                SizedBox(
                  width: 96.0,
                  height: 27.0,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Container(
                      width: 90.0,
                      height: 27.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 1.0,
                          color: Colors.black,
                        ),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: TextButton(
                        style: ButtonStyle(
                          overlayColor: MaterialStateProperty.resolveWith(
                            (Set<MaterialState> states) {
                              return states.contains(MaterialState.pressed)
                                  ? Colors.transparent
                                  : null;
                            },
                          ),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(0.0)),
                          alignment: Alignment.center,
                          backgroundColor:
                              MaterialStateProperty.all(Colors.transparent),
                        ),
                        onPressed: _changeLocationDialog,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_circle_left_outlined,
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              'Wróć',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                textStyle: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimationStart,
                  child: Visibility(
                    visible: isVisible,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10.0, right: 10.0, top: 15),
                      child: SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom > 0
                            ? null
                            : MediaQuery.of(context).size.height - 200,
                        child: _locations.isEmpty
                            ? Card(
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Center(
                                      child: Image.asset(
                                        findLocationImage,
                                        width: 250,
                                        height: 250,
                                        color: Colors.black12,
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 95.0),
                                        child:
                                            Text(findLocationText,
                                                style: GoogleFonts.lato(
                                                  textStyle: const TextStyle(
                                                    fontSize: 18.0,
                                                    height: 1.2,
                                                    color: Colors.black,
                                                  ),
                                                )),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: _locations
                                    .map(
                                      (location) => Column(
                                        children: [
                                          Card(
                                            margin: EdgeInsets.zero,
                                            child: ListTile(
                                              title: Text(location.name),
                                              subtitle: Text(
                                                location.state == ''
                                                    ? location.country
                                                        .toUpperCase()
                                                    : '${location.country.toUpperCase()}, ${location.state}',
                                              ),
                                              onTap: () => setState(() {
                                                _changeSelectedLocation(
                                                    location);
                                              }),
                                            ),
                                          ),
                                          if (_locations.last != location)
                                            const SizedBox(height: 8.0)
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildShowInformationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 60.0),
            child: Container(
                height: 35.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 6.0),
                        Image.asset('assets/map-pin.png', color: Colors.black),
                        const SizedBox(width: 8.0),
                        Text(
                            '${_selectedLocation.name}, ${_selectedLocation.country}',
                            style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                  fontSize: 16.0,
                                  height: 1.2,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                            )),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Container(
                        width: 90.0,
                        height: 27.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            width: 1.0,
                            color: Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                        child: TextButton(
                            style: ButtonStyle(
                                overlayColor: MaterialStateProperty.resolveWith(
                                  (Set<MaterialState> states) {
                                    return states
                                            .contains(MaterialState.pressed)
                                        ? Colors.transparent
                                        : null;
                                  },
                                ),
                                padding: MaterialStateProperty.all(
                                    const EdgeInsets.all(0.0)),
                                alignment: Alignment.center,
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.transparent)),
                            onPressed: _changeLocationDialog,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Zmień',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                      textStyle: const TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    )),
                                const SizedBox(width: 8.0),
                                const Icon(
                                  Icons.arrow_circle_right_outlined,
                                  size: 16,
                                  color: Colors.black,
                                )
                              ],
                            )),
                      ),
                    )
                  ],
                )),
          ),
          const SizedBox(height: 130.0),
          Text(
            'Jakość powietrza',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                  fontSize: 14.0,
                  height: 1.2,
                  color: getBackgroundTextColor(widget.air),
                  fontWeight: FontWeight.w300),
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            widget.air.quality,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                  fontSize: 22.0,
                  height: 1.2,
                  color: getBackgroundTextColor(widget.air),
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24.0),
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 91.0,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text((widget.air.aqi / 200 * 100).floor().toString(),
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                        fontSize: 64.0,
                        height: 1.2,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  )),
              RichText(
                  text: TextSpan(
                      text: 'CAQI ⓘ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _panelController.open();
                        },
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                            fontSize: 16.0,
                            height: 1.2,
                            color: Colors.black,
                            fontWeight: FontWeight.w300),
                      ))),
            ]),
          ),
          const SizedBox(height: 24.0),
          IntrinsicHeight(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('PM 2,5',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                              fontSize: 14.0,
                              height: 1.2,
                              color: getBackgroundTextColor(widget.air),
                              fontWeight: FontWeight.w300),
                        )),
                    Text(widget.air.pm25 == -1 ? '-' : '${widget.air.pm25}%',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                              fontSize: 22.0,
                              height: 1.2,
                              color: getBackgroundTextColor(widget.air),
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                ),
              ),
              VerticalDivider(
                color: getBackgroundTextColor(widget.air),
                width: 48.0,
              ),
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('PM 10',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                              fontSize: 14.0,
                              height: 1.2,
                              color: getBackgroundTextColor(widget.air),
                              fontWeight: FontWeight.w300),
                        )),
                    Text(widget.air.pm10 == -1 ? '-' : '${widget.air.pm10}%',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                              fontSize: 22.0,
                              height: 1.2,
                              color: getBackgroundTextColor(widget.air),
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Wybrana stacja pomiarowa',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                  fontSize: 12.0,
                  height: 1.2,
                  color: getBackgroundTextColor(widget.air),
                  fontWeight: FontWeight.w300),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.air.station,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              textStyle: TextStyle(
                  fontSize: 14.0,
                  height: 1.2,
                  color: getBackgroundTextColor(widget.air)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDangerValueContainer() {
    return Positioned(
        left: 0,
        top: 0,
        right: 0,
        bottom: 76,
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 10.0),
          child: Stack(
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  heightFactor: 1,
                  child: getDangerValueBottom(widget.air),
                ),
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  heightFactor: 1 - widget.air.aqi / 200.floor(),
                  child: getDangerValueTop(widget.air),
                ),
              )
            ],
          ),
        ));
  }

  Widget buildAdviceContainer() {
    return Positioned(
        left: 0,
        bottom: 0,
        right: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 32.0, 10.0, 32.0),
          child: Column(
            children: [
              const Divider(
                color: Colors.black,
                thickness: 1.0,
              ),
              const SizedBox(height: 14.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: Container(
                  width: double.infinity,
                  height: 38.0,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(getAdviceImage(widget.air)),
                      const SizedBox(width: 4.0),
                      Text(
                        widget.air.advice,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                              fontSize: 12.0,
                              height: 1.2,
                              color: Colors.black,
                              fontWeight: FontWeight.w300),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }

  Widget buildSlidingUpPanel() {
    return Positioned(
        left: 0,
        bottom: 0,
        right: 0,
        child: SlidingUpPanel(
          minHeight: 0,
          maxHeight: 300,
          controller: _panelController,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6.0), topRight: Radius.circular(6.0)),
          panel: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 32.0, 22.0, 22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Indeks CAQI',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                            fontSize: 14.0, height: 1.2, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Indeks CAQI (ang. Common Air Quality Index) pozwala przedstawić sytuację w Europie w porównywalny i łatwy do zrozumienia sposób. Wartość indeksu jest prezentowana w postaci jednej liczby. Skala ma rozpietość od 0 do wartości powyżej 100 i powyżej bardzo zanieczyszone. Im wyższa wartość wskażnika, tym większe ryzyko złego wpływu na zdrowie i sampoczucie.',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                            fontSize: 12.0,
                            height: 1.2,
                            color: Colors.black,
                            fontWeight: FontWeight.w300),
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Pył zawieszony PM2,5 i PM10',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                            fontSize: 14.0, height: 1.2, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Pyły zawieszone to mieszanina bardzo małych cząstek. PM10 to wszystkie pyły mniejsze niz 10μm, natomiast w przypadku PM2,5 nie większe niż 2,5μm. Zanieczyszczenia pyłowe mają zdolność do adsorpcji swojej powierzchni innych, bardzo szkodliwych związków chemicznych: dioksyn, furanów, metali ciężkich, czy benzo(a)pirenu - najbardziej toksycznego skłądnika smogu.',
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                            fontSize: 12.0,
                            height: 1.2,
                            color: Colors.black,
                            fontWeight: FontWeight.w300),
                      ),
                    )
                  ],
                ),
              ),
              Positioned(
                  top: 10.0,
                  right: 0,
                  child: TextButton(
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: () {
                      _panelController.close();
                    },
                  ))
            ],
          ),
        ));
  }
}

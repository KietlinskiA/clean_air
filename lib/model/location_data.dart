import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:clean_air/config/my_logger.dart';
import '../config/app_config.dart';

class LocationData {
  String name = '';
  String country = '';
  String state = '';
  double lat = 0.0;
  double lng = 0.0;
  static final Logger logger = AppLogger().logger;

  LocationData.empty() {
    name = '';
    country = '';
    state = '';
    lat = 0.0;
    lng = 0.0;
  }

  LocationData(object) {
    name = _getName(object);
    country = object['components']['country'].toString();
    state = object['components']['state'].toString().toUpperCase() != 'NULL'
        ? object['components']['state'].toString().toUpperCase()
        : '';
    lat = object['geometry']['lat'];
    lng = object['geometry']['lng'];
  }

  String _getName(object) {
    var components = object['components'];
    var name = 'unknown';

    if (components['city'] != null) {
      name = components['city'].toString();
      logger.d('Name from city: $name');
    } else if (components['town'] != null) {
      name = components['town'].toString();
      logger.d('Name from town: $name');
    } else if (components['village'] != null) {
      name = components['village'].toString();
      logger.d('Name from village: $name');
    } else if (components['_normalized_city'] != null) {
      name = components['_normalized_city'].toString();
      logger.d('Name from _normalized_city: $name');
    }

    return toBeginningOfSentenceCase(name);
  }

  @override
  String toString() {
    return 'LocationData{name: $name, country: $country, state: $state, lat: $lat, lng: $lng}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationData &&
          name == other.name &&
          country == other.country &&
          state == other.state;

  @override
  int get hashCode =>
      name.hashCode ^
      country.hashCode ^
      state.hashCode ^
      lat.hashCode ^
      lng.hashCode;

  static Future<List<LocationData>> getLocations(LocationData location) async {
    String query;
    bool isGpsPosition =
        location.name == '' && location.country == '' && location.state == ''
            ? true
            : false;

    isGpsPosition
        ? query = '${location.lat},${location.lng}'
        : query = location.name;

    logger.d('Selected location: $query');
    String endpoint = 'https://api.opencagedata.com/geocode/v1/json';
    var key = AppConfig.geolocationKey;
    String url = '$endpoint?'
        'key=$key&'
        'language=pl&'
        'pretty=1&'
        'address_only=1&'
        'limit=10&'
        'no_annotations=1&'
        'q=$query';

    http.Response response = await http.get(Uri.parse(url));

    Map<String, dynamic> jsonBody = json.decode(response.body);
    List<LocationData> locationDataList = [];
    for (var object in jsonBody['results']) {
      logger.t('===========================');
      logger.t(object['components']['_category'].toString());
      logger.t(object['components']['country'].toString());
      logger.t(object['components']['town'].toString());
      logger.t(object['components']['village'].toString());
      logger.t(object['components']['state'].toString());
      logger.t(object['components']['postcode'].toString());
      logger.t(object['geometry']['lat'].toString());
      logger.t(object['geometry']['lng'].toString());
      logger.t(object['components'].toString());

      if (object['components']['_type'].toString() != 'state' ||
          object['components']['_category'].toString() == 'place') {
        LocationData newLocationData = LocationData(object);
        logger.t('Result object: ${newLocationData.toString()}');

        if (isGpsPosition ||
            (!isGpsPosition &&
                !locationDataList
                    .any((element) => element == newLocationData) &&
                _compare(newLocationData.name, query))) {
          locationDataList.add(newLocationData);
        }
      }
    }

    return locationDataList;
  }

  static bool _compare(String s1, String s2) {
    s1 = removeDiacritics(s1.toLowerCase());
    s2 = removeDiacritics(s2.toLowerCase());
    return s1 == s2;
  }
}

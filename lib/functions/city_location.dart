// ignore_for_file: non_constant_identifier_names

import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/cities.dart';
import 'package:roomy_finder/models/country.dart';

List<String> get CITIES_FROM_CURRENT_COUNTRY {
  if (AppController.instance.country.value.code == Country.UAE.code) {
    return [
      "Abu Dhabi",
      "Ajman",
      "Dubai",
      "Fujairah",
      "Ras Alkhima",
      "Sharjah",
      "Umm Al-Quwain",
    ];
  } else if (AppController.instance.country.value.code ==
      Country.SAUDI_ARABIA.code) {
    return ["Jeddah", "Mecca", "Riyadh", "Tabuk"];
  } else {
    return [];
  }
}

List<String> getLocationsFromCity(String city) {
  if (AppController.instance.country.value.code == Country.UAE.code) {
    switch (city.trim()) {
      case "Abu Dhabi":
        return abuDahbiCities;
      case "Ajman":
        return ajmanCities;
      case "Dubai":
        return dubaiCities;
      case "Fujairah":
        return fujairahCities;
      case "Ras Alkhima":
        return rasAlkimaCities;
      case "Sharjah":
        return sharjahCities;
      case "Umm Al-Quwain":
        return ummAlQuwainCities;
    }
  } else if (AppController.instance.country.value.code ==
      Country.SAUDI_ARABIA.code) {
    switch (city.trim()) {
      case "Jeddah":
        return jeddahCities;
      case "Mecca":
        return meccaCities;
      case "Riyadh":
        return riyadhCities;
      case "Tabuk":
        return tabukCities;
    }
  }

  return [];
}

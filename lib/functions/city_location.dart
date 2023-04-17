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
      "Ras alkhima",
      "Sharjah",
      "Umm al-Quwain",
    ];
  } else if (AppController.instance.country.value.code ==
      Country.SAUDI_ARABIA.code) {
    return ["Jeddah", "Mecca", "Riyadh"];
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
      case "Ras alkhima":
        return rasAlkimaCities;
      case "Sharjah":
        return sharjahCities;
      case "Umm al-Quwain":
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
    }
  }

  return [];
}

// ignore_for_file: non_constant_identifier_names

import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/cities.dart';
import 'package:roomy_finder/models/country.dart';

List<String> get CITIES_FROM_CURRENT_COUNTRY {
  if (AppController.instance.country.value.code == Country.UAE.code) {
    return [
      "Dubai",
      "Abu Dhabi",
      "Sharjah",
      "Ras alkhima",
      "Umm al-Quwain",
      "Fujairah",
      "Ajman",
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
      case "Dubai":
        return dubaiCities;
      case "Abu Dhabi":
        return abuDahbiCities;
      case "Sharjah":
        return sharjahCities;
      case "Ras alkhima":
        return rasAlkimaCities;
      case "Umm al-Quwain":
        return ummAlQuwainCities;
      case "Ajman":
        return ajmanCities;
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

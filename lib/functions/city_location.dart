import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/cities.dart';
import 'package:roomy_finder/models/country.dart';

List<String> getLocations(String city) {
  if (AppController.instance.country.value == Country.UAE) {
    switch (city.trim()) {
      case "Dubai":
        return dubaiCities;
      case "Abu Dhabi":
        return abuDahbiCities;
      case "Sharjah":
        return sharjahCities;
      case "Umm al-Quwain":
        return ummAlQuwainCities;
      case "Fujairah":
        return fujairahCities;
      case "Ajman":
        return ajmanCities;
    }
  } else if (AppController.instance.country.value == Country.SAUDI_ARABIA) {
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

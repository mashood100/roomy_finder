// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:shared_preferences/shared_preferences.dart';

String relativeTimeText(DateTime dateTime) {
  if (dateTime.add(const Duration(minutes: 59)).isAfter(DateTime.now())) {
    return Jiffy(dateTime.toUtc()).fromNow();
  }

  if (dateTime.add(const Duration(hours: 23)).isAfter(DateTime.now())) {
    return Jiffy(dateTime.toUtc()).Hm;
  }

  if (dateTime.add(const Duration(days: 3)).isAfter(DateTime.now())) {
    return Jiffy(dateTime.toUtc()).Hm;
  }

  return Jiffy(dateTime.toUtc()).yMMMEd;
}

Future<void> changeAppCountry(BuildContext context) async {
  final country = await showModalBottomSheet<Country?>(
    context: context,
    builder: (context) {
      return CupertinoScrollbar(
        child: ListView(
          children: supporttedCountries
              .map(
                (e) => ListTile(
                  leading: CircleAvatar(child: Text(e.flag)),
                  onTap: () => Get.back(result: e),
                  title: Text(e.name),
                  trailing: AppController.instance.country.value == e
                      ? const Icon(
                          Icons.check_circle_sharp,
                          color: Colors.green,
                        )
                      : null,
                ),
              )
              .toList(),
        ),
      );
    },
  );
  if (country != null) {
    if (country.code != Country.UAE.code &&
        country.code != Country.SAUDI_ARABIA.code) {
      showToast('Comming soon');
      return;
    }
    AppController.instance.country(country);
  }
}

String formatMoney(num price) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: "fr_FR",
    name: "${AppController.instance.country.value.currencyCode} ",
    decimalDigits: price.toInt() == price.toDouble() ? 0 : 2,
  );

  return formatter.format(price);
}

Future<List<T>> filterListData<T>(
  List<T> data, {
  List<T> excluded = const [],
  Widget Function(T item, bool isSelected)? itemBuilder,
}) async {
  final context = Get.context;
  if (context == null) return [];
  final result = await showModalBottomSheet<List<T>>(
    context: context,
    builder: (context) {
      final selectInterests = <T>[];
      return WillPopScope(
        onWillPop: () async {
          Get.back(result: selectInterests);
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StatefulBuilder(builder: (context, setState) {
            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 3,
              children: data
                  .where((e) => !excluded.contains(e))
                  .map(
                    (e) => GestureDetector(
                      onTap: () {
                        if (selectInterests.contains(e)) {
                          selectInterests.remove(e);
                        } else {
                          selectInterests.add(e);
                        }
                        setState(() {});
                      },
                      child: Card(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 123, 77, 1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          height: 100,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selectInterests.contains(e),
                                onChanged: (_) {
                                  if (selectInterests.contains(e)) {
                                    selectInterests.remove(e);
                                  } else {
                                    selectInterests.add(e);
                                  }
                                  setState(() {});
                                },
                              ),
                              Builder(builder: (context) {
                                if (itemBuilder != null) {
                                  return itemBuilder(
                                      e, selectInterests.contains(e));
                                }
                                return Text(
                                  "$e",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ),
      );
    },
  );

  if (result is List<T>) {
    return result;
  }
  return [];
}

IconData getIconDataFromAmenties(String search) {
  switch (search) {
    case "Close to metro":
      return Icons.car_repair;
    case "Balcony":
      return Icons.window;
    case "Kitchen appliances":
      return Icons.kitchen;
    case "Barking":
      return Icons.bakery_dining;
    case "WIFI":
      return Icons.wifi;
    case "TV":
      return Icons.tv;
    case "Shared gym":
      return Icons.sports_gymnastics;
    case "Washer":
      return Icons.wash;
    case "Cleaning included":
      return Icons.cleaning_services;
    case "Near to supermarket":
      return Icons.shopify;
    case "Shared swimming pool":
      return Icons.water;
    case "Near to pharmacy":
      return Icons.health_and_safety;
    default:
      return Icons.widgets;
  }
}

Future<bool> addAdToFavorite(String item, String listKey) async {
  try {
    final pref = await SharedPreferences.getInstance();

    final favorites = pref.getStringList(listKey) ?? [];
    if (!favorites.contains(item)) {
      favorites.add(item);
    }
    pref.setStringList(listKey, favorites);
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> removeAdFromFavorite(String item, String listKey) async {
  try {
    final pref = await SharedPreferences.getInstance();

    final favorites = pref.getStringList(listKey) ?? [];
    favorites.remove(item);

    pref.setStringList(listKey, favorites);
    return true;
  } catch (_) {
    return false;
  }
}

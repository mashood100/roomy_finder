// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/controllers/app_controller.dart';

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

String formatMoney(num price) {
  final NumberFormat formatter = NumberFormat.currency(
    locale: "en_US",
    name: AppController.instance.country.value.currencyCode,
    decimalDigits: 2,
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
                                  style: const TextStyle(fontSize: 16),
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

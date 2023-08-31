import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/screens/utility_screens/value_sector.dart';

class RoommatesAdsFilterScreen extends StatefulWidget {
  const RoommatesAdsFilterScreen({super.key, this.oldFilter});
  final Map<String, dynamic>? oldFilter;

  @override
  State<RoommatesAdsFilterScreen> createState() =>
      _RoommatesAdsFilterScreenState();
}

class _RoommatesAdsFilterScreenState extends State<RoommatesAdsFilterScreen> {
  late final Map<String, dynamic> filter;

  @override
  void initState() {
    filter = {"amenities": [], "preferences": []};
    if (widget.oldFilter != null) filter.addAll(widget.oldFilter!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filter"),
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: () {
              filter.clear();
              filter.addAll({"amenities": [], "preferences": []});
              setState(() {});
            },
            child: const Text(
              "Reset",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 20, left: 20, bottom: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            InlineSelector(
              items: const ["NEED ROOM", "HAVE ROOM", "All"],
              value: filter["action"] ?? "All",
              onChanged: (value) {
                setState(() {
                  if (value == "All") {
                    filter.remove("action");
                  } else {
                    filter['action'] = value;
                  }
                });
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Apartment type?",
              value: filter["type"] ?? "All types",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Apartment type",
                      data: const [
                        "All",
                        "Studio",
                        "Apartment",
                        "House",
                        "Private room",
                        "Shared room",
                      ],
                      currentValue: filter["type"],
                    ));

                if (val != null) filter["type"] = val;
                if (val == "All") filter.remove("type");
                setState(() {});
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Rent type",
              value: filter["rentType"] ?? "All",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Rent type",
                      data: const ["All", "Monthly", "Weekly", "Daily"],
                      currentValue: filter["rentType"],
                    ));
                if (val != null) filter["rentType"] = val;
                if (val == "All") filter.remove("rentType");
                setState(() {});
              },
            ),
            const Divider(),
            _FilterListile(
              label: "City",
              value: filter["city"] ?? "All cities",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "City",
                      data: ["All", ...CITIES_FROM_CURRENT_COUNTRY],
                      currentValue: filter["city"],
                    ));
                if (val != null && val != filter["city"]) {
                  filter.remove("location");
                  filter["city"] = val;

                  if (val == "All") {
                    filter.remove("city");
                    filter.remove("location");
                  }
                  setState(() {});
                }
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Area",
              value: filter["location"] ?? "All locations",
              onTap: filter["city"] == null
                  ? null
                  : () async {
                      var val = await Get.to(() => ValueSelctorScreen(
                            title: "Location",
                            data: [
                              "All",
                              ...getLocationsFromCity(filter["city"].toString())
                            ],
                            currentValue: filter["location"],
                          ));

                      if (val != null) {
                        setState(() {
                          if (val == "All") {
                            filter.remove("location");
                          } else {
                            filter["location"] = val;
                          }
                        });
                      }
                    },
            ),
            const Divider(),
            _FilterListile(
              label: "Gender",
              value: filter["gender"] ?? "All genders",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Gender",
                      data: const ["All", "Female", "Male", "Mix"],
                      currentValue: filter["gender"] ?? "All",
                    ));

                if (val != null) {
                  setState(() {
                    filter["gender"] = val;
                    if (val == "All") filter.remove("gender");
                  });
                }
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Nationality",
              value: filter["nationality"] ?? "Mix",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Nationality",
                      data: ALL_NATIONALITIES,
                      currentValue: filter["nationality"],
                    ));
                if (val != null) {
                  filter["nationality"] = val;

                  if (val == "Mix") {
                    filter.remove("nationality");
                  }
                  setState(() {});
                }
              },
            ),
            const Divider(),
            const Text(
              "Budget",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: InlineTextField(
                    labelWidth: 0,
                    suffixText:
                        AppController.instance.country.value.currencyCode,
                    hintText: 'Minimum',
                    initialValue: filter["minBudget"],
                    onChanged: (value) {
                      setState(() {
                        filter["minBudget"] = value;
                      });
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(priceRegex)
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InlineTextField(
                    labelWidth: 0,
                    suffixText:
                        AppController.instance.country.value.currencyCode,
                    hintText: 'Maximum',
                    initialValue: filter["maxBudget"],
                    onChanged: (value) {
                      setState(() {
                        filter["maxBudget"] = value;
                      });
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(priceRegex)
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Amenities",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () async {
                    final val = await Get.to(() => ValueSelctorScreen(
                          title: "Amenities",
                          leadingBuilder: (item) {
                            var firstWhere = ALL_AMENITIES
                                .firstWhere((e) => e["value"] == item);
                            return Image.asset(
                              firstWhere["asset"]!,
                              color: Colors.grey,
                              height: 30,
                            );
                          },
                          data: ALL_AMENITIES
                              .map((e) => e["value"].toString())
                              .toList(),
                          selectionValues:
                              List<String>.from(filter["amenities"]),
                        ));
                    if (val is List) {
                      setState(() {
                        filter["amenities"] = val;
                      });
                    }
                  },
                  icon: const Icon(CupertinoIcons.add, size: 15),
                )
              ],
            ),
            if (filter["amenities"].isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Filter with amenities",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                runSpacing: 5,
                spacing: 5,
                children: List<String>.from(filter["amenities"]).map((e) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              filter["amenities"].remove(e);
                            });
                          },
                          child: const Icon(Icons.cancel),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Preferences",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () async {
                    final val = await Get.to(() {
                      return ValueSelctorScreen<Map<String, String>>(
                        title: "Preferences",
                        getLabel: (item) => item["label"].toString(),
                        leadingBuilder: (item) => Image.asset(
                          item["asset"].toString(),
                          color: Colors.grey,
                          height: 30,
                        ),
                        data: ALL_SOCIAL_PREFERENCES,
                        selectionValues: List<Map<String, String>>.from(
                            filter['preferences']),
                      );
                    });
                    if (val is List) {
                      filter['preferences'] = val;
                      setState(() {});
                    }
                  },
                  icon: const Icon(CupertinoIcons.add, size: 15),
                )
              ],
            ),
            if (filter["preferences"].isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Filter with preferences",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                runSpacing: 5,
                spacing: 5,
                children: List<Map<String, String>>.from(filter["preferences"])
                    .map((e) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e["label"].toString()),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              filter["preferences"].remove(e);
                            });
                          },
                          child: const Icon(Icons.cancel),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            const Divider(),
          ],
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: CustomButton(
          'Show results',
          onPressed: () {
            Get.back(result: filter);
          },
        ),
      ),
    );
  }
}

class _FilterListile extends StatelessWidget {
  const _FilterListile({
    required this.label,
    this.value,
    this.onTap,
  });

  final String label;
  final dynamic value;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (value != null)
              Text(
                '$value',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(width: 10),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

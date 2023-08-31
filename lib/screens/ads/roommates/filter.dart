import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/countries_list.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/screens/utility_screens/value_sector.dart';
import 'package:roomy_finder/utilities/data.dart';

class RoommateUsersFilterScreen extends StatefulWidget {
  const RoommateUsersFilterScreen({super.key, this.oldFilter});
  final Map<String, dynamic>? oldFilter;

  @override
  State<RoommateUsersFilterScreen> createState() =>
      _RoommateUsersFilterScreenState();
}

class _RoommateUsersFilterScreenState extends State<RoommateUsersFilterScreen> {
  late final Map<String, dynamic> filter;

  @override
  void initState() {
    filter = {"languages": [], "preferences": []};
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
              filter.addAll({"languages": [], "preferences": []});
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
            _FilterListile(
              label: "Profile picture",
              value: filter["withProfilePicture"] ?? "All",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Profile picture",
                      data: const ["All", "With picture", "Without picture"],
                      currentValue: filter["withProfilePicture"] ?? "All",
                    ));

                if (val != null) {
                  setState(() {
                    filter["withProfilePicture"] = val;
                    if (val == "All") filter.remove("withProfilePicture");
                  });
                }
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Gender",
              value: filter["gender"] ?? "Mix",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Gender",
                      data: const ["Mix", "Female", "Male"],
                      currentValue: filter["gender"] ?? "Mix",
                    ));

                if (val != null) {
                  setState(() {
                    filter["gender"] = val;
                    if (val == "Mix") filter.remove("gender");
                  });
                }
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Country",
              value: filter["country"] ?? "Mix",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Country",
                      data: ["Mix", ...COUNTRIES_LIST.map((e) => e.name)],
                      currentValue: filter["country"] ?? "Mix",
                    ));
                if (val != null) {
                  filter["country"] = val;

                  if (val == "Mix") {
                    filter.remove("country");
                  }
                  setState(() {});
                }
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Occupation",
              value: filter["occupation"] ?? "All",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Occupation",
                      data: const ["All", ...ALL_OCCUPATIONS],
                      currentValue: filter["occupation"] ?? "All",
                    ));

                if (val != null) {
                  setState(() {
                    filter["occupation"] = val;
                    if (val == "All") filter.remove("occupation");
                  });
                }
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Life style",
              value: filter["lifeStyle"] ?? "All",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Life style",
                      data: const ["All", ...ALL_LIFE_STYLES],
                      currentValue: filter["lifeStyle"] ?? "All",
                    ));

                if (val != null) {
                  setState(() {
                    filter["lifeStyle"] = val;
                    if (val == "All") filter.remove("lifeStyle");
                  });
                }
              },
            ),
            const Divider(),
            _FilterListile(
              label: "Sign",
              value: filter["astrologicalSign"] ?? "All",
              onTap: () async {
                var val = await Get.to(() => ValueSelctorScreen(
                      title: "Sign",
                      data: ["All", ...ASTROLOGICAL_SIGNS.map((e) => e.value)],
                      currentValue: filter["astrologicalSign"] ?? "All",
                    ));

                if (val != null) {
                  setState(() {
                    filter["astrologicalSign"] = val;
                    if (val == "All") filter.remove("astrologicalSign");
                  });
                }
              },
            ),
            const Divider(),
            const Text(
              "Age",
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
                    initialValue: filter["minAge"],
                    onChanged: (value) {
                      setState(() {
                        filter["minAge"] = value;
                      });
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
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
                    initialValue: filter["maxAge"],
                    onChanged: (value) {
                      setState(() {
                        filter["maxAge"] = value;
                      });
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
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
                  "Languages",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () async {
                    final val = await Get.to(() => ValueSelctorScreen(
                          title: "Languages",
                          data: ALL_LANGUAGUES,
                          selectionValues:
                              List<String>.from(filter["languages"]),
                        ));
                    if (val is List) {
                      setState(() {
                        filter["languages"] = val;
                      });
                    }
                  },
                  icon: const Icon(CupertinoIcons.add, size: 15),
                )
              ],
            ),
            if (filter["languages"].isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Filter with languages",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Wrap(
                runSpacing: 5,
                spacing: 5,
                children: List<String>.from(filter["languages"]).map((e) {
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
                              filter["languages"].remove(e);
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

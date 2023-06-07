import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/maintenance/helpers/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/request/choose_maitenance.dart';
import 'package:roomy_finder/maintenance/screens/request/summary.dart';

class RequestMaintenanceScreen extends StatelessWidget {
  const RequestMaintenanceScreen({super.key});
  static String? _category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Maintenance"),
        bottom: PreferredSize(
          preferredSize: Size(Get.width, 150),
          child: Image.asset(
            "assets/maintenance/maintenance.jpg",
            fit: BoxFit.fitWidth,
            height: 150,
            width: Get.width,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Maitenance"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                {
                  "value": "Air Conditioner",
                  "icon": "assets/maintenance/ac_1.png"
                },
                {
                  "value": "Plumbing",
                  "icon": "assets/maintenance/plumbing_7.png"
                },
                {
                  "value": "Electrical",
                  "icon": "assets/maintenance/electric_1.png"
                },
              ]
                  .map((e) => _MaintenanceCard(
                        value: e["value"]!,
                        iconAsset: e["icon"]!,
                        width: Get.width / 4,
                        height: Get.width / 4,
                        onTap: () {
                          _category = e["value"]!;
                          Get.to(() {
                            return ChooseMaintenanceScreen(
                              category: e["value"]!,
                              onFinished: _onFinishedHandler,
                            );
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text("Cleaning"),
            Row(
              children: [
                {
                  "value": "Cleaning",
                  "icon": "assets/maintenance/cleaning_1.png",
                },
              ]
                  .map(
                    (e) => _MaintenanceCard(
                      value: e["value"]!,
                      iconAsset: e["icon"]!,
                      width: Get.width / 4,
                      height: Get.width / 4,
                      onTap: () {
                        _category = e["value"]!;
                        Get.to(() {
                          return ChooseMaintenanceScreen(
                            category: e["value"]!,
                            onFinished: _onFinishedHandler,
                          );
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text("Home Improvement"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ...[
                  {
                    "value": "Painting",
                    "icon": "assets/maintenance/painting_1.png",
                  },
                  {
                    "value": "Handy Man",
                    "icon": "assets/maintenance/hm_1.png",
                  },
                ].map(
                  (e) => _MaintenanceCard(
                    value: e["value"]!,
                    iconAsset: e["icon"]!,
                    width: Get.width / 4,
                    height: Get.width / 4,
                    onTap: () {
                      _category = e["value"]!;
                      Get.to(() {
                        return ChooseMaintenanceScreen(
                          category: e["value"]!,
                          onFinished: _onFinishedHandler,
                        );
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: Get.width / 4,
                  height: Get.width / 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onFinishedHandler(String subCategory, String maintenance) {
    Get.to(() => RequestSummaryScreen(
          request: PostMaintenanceRequest(
            category: _category!,
            maintenances: [
              MaintenanceEntry(
                subCategory: subCategory,
                name: maintenance,
                quantity: 1,
              )
            ],
            date: DateTime.now(),
            address: {},
            images: [],
            description: "",
          ),
        ));
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.value,
    required this.iconAsset,
    required this.width,
    required this.height,
    required this.onTap,
  });
  final String value;
  final String iconAsset;
  final double width;
  final double height;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          width: width,
          height: height,
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                iconAsset,
                height: height / 3,
              ),
              const Spacer(),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              )
            ],
          ),
        ),
      ),
    );
  }
}

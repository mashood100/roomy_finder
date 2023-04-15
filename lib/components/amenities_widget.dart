import 'package:flutter/material.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/utilities/data.dart';

class AmenitiesWidget extends StatelessWidget {
  const AmenitiesWidget({
    super.key,
    this.ad,
    this.labelSuffix,
    this.iconColor,
  }) : assert(ad is RoommateAd || ad is PropertyAd);
  final dynamic ad;
  final String? labelSuffix;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Image.asset(
                    "assets/icons/washer.png",
                    height: 25,
                    color: iconColor,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "APPLIANCES",
                    style: TextStyle(
                      color: ROOMY_ORANGE,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ...ad.homeAppliancesAmenities.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    "${labelSuffix ?? "-"}    $e",
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList()
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Image.asset(
                    "assets/icons/wifi.png",
                    height: 25,
                    color: iconColor,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "TECH",
                    style: TextStyle(
                      color: ROOMY_ORANGE,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ...ad.technologyAmenities.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    "${labelSuffix ?? "-"}     $e",
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList()
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/utilities.png",
                      height: 30,
                      color: iconColor,
                    ),
                    const Text(
                      "UTILITIES",
                      style: TextStyle(
                        color: ROOMY_ORANGE,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 0),
              ...ad.utilitiesAmenities.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    "${labelSuffix ?? "-"}     $e",
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList()
            ],
          ),
        ],
      ),
    );
  }
}

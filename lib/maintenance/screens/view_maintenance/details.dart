import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/maintenance/helpers/maintenance.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';

class ViewMaintenanceDetailsScreen extends StatelessWidget {
  const ViewMaintenanceDetailsScreen({super.key, required this.maintenance});

  final Maintenance maintenance;

  Maintenance get m => maintenance;

  @override
  Widget build(BuildContext context) {
    final address = m.address;
    final tasks = m.tasks;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Maintenance (${m.category})",
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.isPaid)
                if (m.isMine) ...[
                  const Center(child: Text("Maintenant info")),
                  ...[
                    {"label": "Name", "value": m.maintenant?.fullName},
                    {"label": "Phone", "value": m.maintenant?.phone},
                    {"label": "Email", "value": m.maintenant?.email},
                  ].map((e) => _Label("${e["label"]}", "${e["value"]}")),
                ] else ...[
                  const Center(child: Text("Landlord info")),
                  ...[
                    {"label": "Name", "value": m.landlord.fullName},
                    {"label": "Phone", "value": m.landlord.phone},
                    {"label": "Email", "value": m.landlord.email},
                  ].map((e) => _Label("${e["label"]}", "${e["value"]}")),
                ],
              const Divider(),
              ...[
                {"label": "City", "value": address['city']},
                {"label": "Location", "value": address['location']},
                {
                  "label": "Building Name",
                  "value": address['buildingName'] ?? "Not Provided",
                },
                {
                  "label": "Appartment Number",
                  "value": address['appartmentNumber'] ?? "Not Provided",
                },
                {
                  "label": "Floor Number",
                  "value": address['floorNumber'] ?? "Not Provided",
                },
                {"divider": true},
                {
                  "label": "Date",
                  "value": Jiffy.parseFromDateTime(m.date).yMMMEdjm
                },
                {"label": "Status", "value": m.status},
                {
                  "label": "Payment status",
                  "value": m.isPaid ? "Paid" : "Not Paid",
                },
              ].map(
                (e) {
                  if (e["divider"] == true) return const Divider();

                  return _Label("${e["label"]}", "${e["value"]}");
                },
              ),
              const Divider(),
              ...tasks.map((e) => Text("${e.name} (${e.quantity})")),
              const Divider(),
              if (m.description != null)
                Text(
                  m.description!,
                  style: const TextStyle(color: Colors.grey),
                ),
              if (m.images.isNotEmpty)
                GridView.count(
                  crossAxisCount: Get.width > 370 ? 4 : 3,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: m.images.map((e) {
                    return GestureDetector(
                      onTap: () {
                        Get.to(transition: Transition.zoom, () {
                          return ViewImages(
                            images: m.images
                                .map((e) => CachedNetworkImageProvider(e))
                                .toList(),
                            initialIndex: m.images.indexOf(e),
                            title: "Maintenance pictures",
                          );
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: e,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                const Text(
                  "No images",
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: [
      TextSpan(
        text: label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const TextSpan(text: "  :  "),
      TextSpan(text: value),
    ]));
  }
}
